# ============================================================================
# Lab 03: Remote Backend Configuration
# Uses the S3 bucket and DynamoDB table created in Lab 00
# ============================================================================

terraform {
  backend "s3" {
    bucket         = "aws-lab-dev-terraform-state"
    key            = "lab-03-serverless-api/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "aws-lab-dev-terraform-lock"
    encrypt        = true
  }
}
