# =============================================================================
# Variables for Lab 07: Data Pipeline
# =============================================================================

variable "region" {
  description = "AWS region for the data pipeline resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name prefix for all resources in this lab"
  type        = string
  default     = "lab07-data-pipeline"
}

variable "shard_count" {
  description = "Number of shards for the Kinesis Data Stream. Each shard supports 1MB/s input, 2MB/s output"
  type        = number
  default     = 1

  validation {
    condition     = var.shard_count >= 1 && var.shard_count <= 10
    error_message = "Shard count must be between 1 and 10 for this lab."
  }
}
