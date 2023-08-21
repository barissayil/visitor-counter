provider "aws" {
  region = var.region
}

locals {
  unique_id = substr(uuid(), 0, 8)
}

resource "aws_dynamodb_table" "visitor_count" {
  name         = "visitor_count"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_s3_bucket" "website" {
  bucket = "visitor-counter-${local.unique_id}"
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}


resource "aws_iam_role" "lambda_execution_role" {
  name = "visitor_counter_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb_access" {
  name        = "VisitorCounterDynamoDBAccess"
  description = "Policy to allow Lambda to read/write to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.visitor_count.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb_access" {
  policy_arn = aws_iam_policy.dynamodb_access.arn
  role       = aws_iam_role.lambda_execution_role.name
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda/"
  output_path = "/tmp/lambda_function_payload.zip"
}

resource "aws_lambda_function" "visitor_counter_function" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "visitor_counter_function"
  handler       = "index.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_execution_role.arn
}

resource "aws_api_gateway_rest_api" "visitor_counter_api" {
  name        = "VisitorCounterAPI"
  description = "API for Visitor Counter app"
}

resource "aws_api_gateway_resource" "visitor_resource" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  parent_id   = aws_api_gateway_rest_api.visitor_counter_api.root_resource_id
  path_part   = "count"
}

resource "aws_api_gateway_method" "visitor_get" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.visitor_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.visitor_counter_function.invoke_arn
}

resource "aws_api_gateway_deployment" "visitor_counter_deployment" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  stage_name  = "default"

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter_function.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_api_gateway_method" "visitor_options" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_mock" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.visitor_options.http_method

  type = "MOCK"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.visitor_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.visitor_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options_mock]
}


resource "aws_api_gateway_method_response" "get_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.visitor_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "get" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.visitor_get.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [aws_api_gateway_integration.lambda_integration]
}

resource "aws_s3_object" "website_index" {
  bucket       = aws_s3_bucket.website.bucket
  key          = "index.html"
  source       = "../website/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "website_css" {
  bucket       = aws_s3_bucket.website.bucket
  key          = "styles.css"
  source       = "../website/styles.css"
  content_type = "text/css"
}

resource "aws_s3_object" "website_js" {
  bucket       = aws_s3_bucket.website.bucket
  key          = "script.js"
  content      = data.template_file.script_js.rendered
  content_type = "application/javascript"
}

data "template_file" "script_js" {
  template = file("../website/script.js.tpl")

  vars = {
    api_endpoint = aws_api_gateway_deployment.visitor_counter_deployment.invoke_url
  }
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicRead",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

