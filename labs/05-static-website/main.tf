# =============================================================================
# Lab 05: Static Website Hosting with S3 + CloudFront
# S3 (origin) + CloudFront CDN + Optional Route53 & ACM
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "static-website"
      Lab       = "05-static-website"
      ManagedBy = "terraform"
    }
  }
}

# Provider in us-east-1 required for ACM certificates used by CloudFront
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "static-website"
      Lab       = "05-static-website"
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

# =============================================================================
# S3 BUCKET - Website content origin
# =============================================================================

# S3 bucket to store static website files
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

# Block all public access - CloudFront OAC will be the only access method
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy allowing CloudFront OAC to read objects
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Upload sample index.html
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.module}/website/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/index.html")

  tags = {
    Name = "index.html"
  }
}

# Upload sample error.html
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  source       = "${path.module}/website/error.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/website/error.html")

  tags = {
    Name = "error.html"
  }
}

# =============================================================================
# CLOUDFRONT - CDN Distribution
# =============================================================================

# Origin Access Control: secure access from CloudFront to S3 (replaces legacy OAI)
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for static website S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution serving content from S3
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "Static website distribution for ${var.bucket_name}"
  price_class         = "PriceClass_100" # North America and Europe only (cheapest)

  # Use custom domain if provided
  aliases = var.domain_name != "" ? [var.domain_name] : []

  # S3 origin configuration with OAC
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"

    # Use managed caching policy (CachingOptimized)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    compress = true
  }

  # Custom error response for SPA: redirect 404 to index.html
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  # Custom error response for 403 (S3 returns 403 for non-existent objects with OAC)
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  # SSL certificate configuration
  viewer_certificate {
    # Use ACM certificate if domain is provided, otherwise use CloudFront default
    cloudfront_default_certificate = var.domain_name == "" ? true : false
    acm_certificate_arn            = var.domain_name != "" ? aws_acm_certificate.website[0].arn : null
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.domain_name != "" ? "TLSv1.2_2021" : null
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "${var.bucket_name}-distribution"
  }
}

# =============================================================================
# ACM CERTIFICATE (Optional - only if domain_name is provided)
# Must be in us-east-1 for CloudFront
# =============================================================================

resource "aws_acm_certificate" "website" {
  count    = var.domain_name != "" ? 1 : 0
  provider = aws.us_east_1

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.domain_name}-certificate"
  }
}

# =============================================================================
# ROUTE 53 (Optional - only if domain_name is provided)
# =============================================================================

# Look up existing hosted zone if domain is provided
data "aws_route53_zone" "website" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name
}

# DNS record for ACM certificate validation
resource "aws_route53_record" "acm_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.website[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = data.aws_route53_zone.website[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]

  allow_overwrite = true
}

# Wait for ACM certificate to be validated
resource "aws_acm_certificate_validation" "website" {
  count    = var.domain_name != "" ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.website[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

# A record (alias) pointing domain to CloudFront distribution
resource "aws_route53_record" "website" {
  count = var.domain_name != "" ? 1 : 0

  zone_id = data.aws_route53_zone.website[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
