output "api_invoke_url" {
  value = aws_api_gateway_deployment.visitor_counter_deployment.invoke_url
}

output "api_id" {
  value = aws_api_gateway_rest_api.visitor_counter_api.id
}
