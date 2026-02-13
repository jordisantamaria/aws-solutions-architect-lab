# ============================================================================
# Lab 01: Remote Backend Configuration
# Uses the S3 bucket and DynamoDB table created in Lab 00
# ============================================================================
# IMPORTANT: Update the bucket and dynamodb_table values with the actual
# names from Lab 00 outputs before running terraform init.
# ============================================================================

terraform {
  backend "s3" {
    bucket         = "aws-lab-dev-terraform-state"
    key            = "lab-01-vpc-networking/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "aws-lab-dev-terraform-lock"
    encrypt        = true
  }
}
