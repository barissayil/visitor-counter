# Visitor Counter

This project uses Terraform to set up a visitor counter website with Lambda, DynamoDB, API Gateway, and S3 services. The Lambda function updates the DynamoDB table with visitor counts, and the website content is hosted on S3.

## Usage

1. Ensure that Terraform is installed on your local machine, and you have the necessary AWS credentials set up.

2. Run `cd terraform` to navigate to the Terraform directory.

3. Run `terraform init` to initialize the Terraform workspace.

4. Run `terraform apply` to create the AWS resources.

5. Once the resources have been created, Terraform will output the website URL. You can access the webpage by navigating to `website_url` in a web browser.

**Note:** Remember to run `terraform destroy` when you're done to delete the resources and avoid unnecessary AWS charges.
