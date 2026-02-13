# =============================================================================
# Outputs for Lab 06: Event-Driven Architecture
# =============================================================================

output "s3_bucket_name" {
  description = "Name of the S3 uploads bucket (event source)"
  value       = aws_s3_bucket.uploads.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 uploads bucket"
  value       = aws_s3_bucket.uploads.arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for file events"
  value       = aws_sns_topic.file_events.arn
}

output "sqs_image_processor_url" {
  description = "URL of the image processor SQS queue"
  value       = aws_sqs_queue.image_processor.url
}

output "sqs_audit_logger_url" {
  description = "URL of the audit logger SQS queue"
  value       = aws_sqs_queue.audit_logger.url
}

output "sqs_api_messages_url" {
  description = "URL of the API messages SQS queue"
  value       = aws_sqs_queue.api_messages.url
}

output "api_endpoint" {
  description = "API Gateway endpoint URL for sending messages directly to SQS"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "lambda_image_processor_name" {
  description = "Name of the image processor Lambda function"
  value       = aws_lambda_function.image_processor.function_name
}

output "lambda_audit_logger_name" {
  description = "Name of the audit logger Lambda function"
  value       = aws_lambda_function.audit_logger.function_name
}
