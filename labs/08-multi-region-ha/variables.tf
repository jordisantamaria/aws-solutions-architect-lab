# =============================================================================
# Variables for Lab 08: Multi-Region High Availability
# =============================================================================

variable "primary_region" {
  description = "Primary AWS region (active region for writes)"
  type        = string
  default     = "eu-west-1"
}

variable "secondary_region" {
  description = "Secondary AWS region (standby region for failover)"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Domain name for Route53 hosted zone (e.g., example.com)"
  type        = string
  default     = "lab-multiregion.example.com"
}

variable "project_name" {
  description = "Name prefix for all resources in this lab"
  type        = string
  default     = "lab08-multi-region"

  validation {
    condition     = length(var.project_name) <= 30
    error_message = "Project name must be 30 characters or fewer for resource naming limits."
  }
}
