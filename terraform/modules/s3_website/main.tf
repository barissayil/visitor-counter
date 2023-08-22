resource "random_string" "s3_bucket_sufix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "website" {
  bucket = "visitor-counter-${random_string.s3_bucket_sufix.result}"
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.website.id
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "website_index" {
  bucket       = aws_s3_bucket.website.bucket
  key          = "index.html"
  source       = var.index_source
  content_type = "text/html"
}

resource "aws_s3_object" "website_css" {
  bucket       = aws_s3_bucket.website.bucket
  key          = "styles.css"
  source       = var.css_source
  content_type = "text/css"
}

resource "aws_s3_object" "website_js" {
  bucket       = aws_s3_bucket.website.bucket
  key          = "script.js"
  content      = var.script_content
  content_type = "application/javascript"
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
