# =============================================================================
# Variables for Lab 04: Three-Tier Architecture
# =============================================================================

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name of the project, used as prefix for all resources"
  type        = string
  default     = "three-tier"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "db_name" {
  description = "Name of the Aurora PostgreSQL database"
  type        = string
  default     = "appdb"
}

variable "container_image" {
  description = "Docker image for the ECS task (using nginx as placeholder)"
  type        = string
  default     = "nginx:alpine"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}
