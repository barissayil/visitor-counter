output "website_url" {
  value = "http://${module.s3_website.website_bucket_name}.s3-website-${var.region}.amazonaws.com/"
}

output "api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.visitor_counter_api.id}.execute-api.${var.region}.amazonaws.com/default/count"
}
