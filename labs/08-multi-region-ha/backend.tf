# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# Stores Terraform state in S3 with DynamoDB locking.
# Update the bucket and DynamoDB table names to match your setup.

terraform {
  backend "s3" {
    bucket         = "aws-sa-lab-terraform-state"
    key            = "labs/08-multi-region-ha/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
