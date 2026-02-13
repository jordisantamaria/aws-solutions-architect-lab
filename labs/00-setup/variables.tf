# ============================================================================
# Lab 00: Input Variables
# ============================================================================

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name of the project, used as prefix for resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
