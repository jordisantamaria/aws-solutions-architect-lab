# =============================================================================
# Outputs for Lab 08: Multi-Region High Availability
# =============================================================================

# --- DNS ---

output "route53_app_url" {
  description = "Application URL via Route53 failover DNS"
  value       = "http://app.${var.domain_name}"
}

output "route53_nameservers" {
  description = "Route53 nameservers for the hosted zone"
  value       = aws_route53_zone.main.name_servers
}

# --- Primary Region ---

output "primary_alb_dns" {
  description = "DNS name of the primary region ALB"
  value       = aws_lb.primary.dns_name
}

output "primary_alb_url" {
  description = "URL of the primary region ALB"
  value       = "http://${aws_lb.primary.dns_name}"
}

output "primary_aurora_endpoint" {
  description = "Aurora writer endpoint in the primary region"
  value       = aws_rds_cluster.primary.endpoint
}

output "primary_aurora_reader_endpoint" {
  description = "Aurora reader endpoint in the primary region"
  value       = aws_rds_cluster.primary.reader_endpoint
}

output "primary_s3_bucket" {
  description = "S3 bucket in the primary region (CRR source)"
  value       = aws_s3_bucket.primary.id
}

# --- Secondary Region ---

output "secondary_alb_dns" {
  description = "DNS name of the secondary region ALB"
  value       = aws_lb.secondary.dns_name
}

output "secondary_alb_url" {
  description = "URL of the secondary region ALB"
  value       = "http://${aws_lb.secondary.dns_name}"
}

output "secondary_aurora_endpoint" {
  description = "Aurora endpoint in the secondary region (read-only until failover)"
  value       = aws_rds_cluster.secondary.endpoint
}

output "secondary_aurora_reader_endpoint" {
  description = "Aurora reader endpoint in the secondary region"
  value       = aws_rds_cluster.secondary.reader_endpoint
}

output "secondary_s3_bucket" {
  description = "S3 bucket in the secondary region (CRR destination)"
  value       = aws_s3_bucket.secondary.id
}

# --- Global Database ---

output "global_cluster_identifier" {
  description = "Aurora Global Database cluster identifier"
  value       = aws_rds_global_cluster.main.global_cluster_identifier
}

# --- Health Check ---

output "health_check_id" {
  description = "Route53 health check ID for the primary ALB"
  value       = aws_route53_health_check.primary.id
}
