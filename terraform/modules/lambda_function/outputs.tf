output "lambda_invoke_arn" {
  value = aws_lambda_function.visitor_counter_function.invoke_arn
}
