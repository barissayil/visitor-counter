output "website_bucket_name" {
  description = "The name of the S3 website bucket"
  value       = aws_s3_bucket.website.bucket
}
