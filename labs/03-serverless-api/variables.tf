# ============================================================================
# Lab 03: Input Variables
# ============================================================================

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name of the project, used as prefix for resource naming"
  type        = string
  default     = "aws-lab"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}
