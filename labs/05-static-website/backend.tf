# =============================================================================
# S3 Backend Configuration for Lab 05: Static Website Hosting
# =============================================================================
# Before using this backend, ensure the S3 bucket and DynamoDB table exist.
# You can create them with Lab 00 (setup) or manually.
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "aws-lab-tfstate-ACCOUNT-ID"
    key            = "labs/05-static-website/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
