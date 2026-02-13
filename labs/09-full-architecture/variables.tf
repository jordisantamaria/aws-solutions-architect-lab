# =============================================================================
# Variables for Lab 09: Full Architecture (E-Commerce Platform)
# =============================================================================

variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name prefix for all resources in this lab"
  type        = string
  default     = "lab09-ecommerce"

  validation {
    condition     = length(var.project_name) <= 25
    error_message = "Project name must be 25 characters or fewer for resource naming limits."
  }
}

variable "environment" {
  description = "Environment name (used for API Gateway stage and resource tagging)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "domain_name" {
  description = "Domain name for the application (optional, for future Route53 setup)"
  type        = string
  default     = "ecommerce-lab.example.com"
}

# --- Database Configuration ---

variable "db_name" {
  description = "Name of the Aurora PostgreSQL database"
  type        = string
  default     = "ecommerce"
}

variable "db_min_capacity" {
  description = "Minimum ACU for Aurora Serverless v2 (0.5 is the minimum)"
  type        = number
  default     = 0.5

  validation {
    condition     = var.db_min_capacity >= 0.5
    error_message = "Minimum ACU must be at least 0.5."
  }
}

variable "db_max_capacity" {
  description = "Maximum ACU for Aurora Serverless v2"
  type        = number
  default     = 2.0

  validation {
    condition     = var.db_max_capacity >= 1.0 && var.db_max_capacity <= 128.0
    error_message = "Maximum ACU must be between 1.0 and 128.0."
  }
}
