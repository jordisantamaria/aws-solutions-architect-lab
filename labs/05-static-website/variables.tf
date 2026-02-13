# =============================================================================
# Variables for Lab 05: Static Website Hosting
# =============================================================================

variable "region" {
  description = "AWS region to deploy resources (S3 bucket region)"
  type        = string
  default     = "eu-west-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket hosting the website"
  type        = string
  default     = "aws-lab-static-website"
}

variable "domain_name" {
  description = "Custom domain name for the website (optional - leave empty to use CloudFront domain)"
  type        = string
  default     = ""
}
