# =============================================================================
# Outputs for Lab 05: Static Website Hosting
# =============================================================================

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (useful for cache invalidation)"
  value       = aws_cloudfront_distribution.website.id
}

output "website_url" {
  description = "URL to access the static website"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket storing website files"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}
