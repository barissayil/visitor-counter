provider "aws" {
  region = var.region
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda/"
  output_path = "/tmp/lambda_function_payload.zip"
}

data "template_file" "script_js" {
  template = file("../website/script.js.tpl")

  vars = {
    api_endpoint = module.api_gateway.api_invoke_url
  }
}

module "s3_website" {
  source         = "./modules/s3_website"
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
  lambda_function_arn = module.lambda_function.lambda_invoke_arn
}

module "lambda_function" {
  source                 = "./modules/lambda_function"
  dynamodb_table_arn     = module.dynamodb_table.dynamodb_table_arn
  lambda_source_zip_path = data.archive_file.lambda_zip.output_path
}
