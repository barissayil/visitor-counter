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
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dynamodb_access" {
  policy_arn = aws_iam_policy.dynamodb_access.arn
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_lambda_function" "visitor_counter_function" {
  filename      = var.lambda_source_zip_path
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