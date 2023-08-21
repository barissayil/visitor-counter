variable "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  type        = string
}

variable "lambda_source_zip_path" {
  description = "Path to the source zip for the Lambda function"
  type        = string
}
