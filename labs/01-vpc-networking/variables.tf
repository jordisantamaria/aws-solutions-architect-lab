# ============================================================================
# Lab 01: Input Variables
# ============================================================================

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
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

variable "my_ip" {
  description = "Your public IP address in CIDR notation for SSH access (e.g., 203.0.113.50/32)"
  type        = string
  default     = "0.0.0.0/0"
}
