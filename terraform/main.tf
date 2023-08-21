provider "aws" {
  region = var.region
}

locals {
  unique_id = substr(uuid(), 0, 8)
}

module "s3_website" {
  source         = "./modules/s3_website"
  unique_id      = local.unique_id
  index_source   = "../website/index.html"
  css_source     = "../website/styles.css"
  script_content = data.template_file.script_js.rendered
}

module "dynamodb_table" {
  source     = "./modules/dynamodb_table"
  table_name = "visitor_count"
}

module "api_gateway" {
  source              = "./modules/api_gateway"
  lambda_function_arn = aws_lambda_function.visitor_counter_function.invoke_arn
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
        Resource = module.dynamodb_table.dynamodb_table_arn
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

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter_function.function_name
  principal     = "apigateway.amazonaws.com"
}

data "template_file" "script_js" {
  template = file("../website/script.js.tpl")

  vars = {
    api_endpoint = module.api_gateway.api_invoke_url
  }
}
