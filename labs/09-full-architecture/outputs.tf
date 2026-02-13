# =============================================================================
# Outputs for Lab 09: Full Architecture (E-Commerce Platform)
# =============================================================================

# --- Authentication ---

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID (use this for authentication)"
  value       = aws_cognito_user_pool_client.main.id
}

# --- Frontend ---

output "cloudfront_distribution_url" {
  description = "CloudFront distribution URL for the frontend"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "frontend_bucket" {
  description = "S3 bucket for frontend static files"
  value       = aws_s3_bucket.frontend.id
}

# --- API ---

output "api_gateway_url" {
  description = "API Gateway base URL"
  value       = "${aws_api_gateway_stage.prod.invoke_url}"
}

output "api_products_url" {
  description = "URL to get products"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/products"
}

output "api_orders_url" {
  description = "URL to create orders"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/orders"
}

# --- Database ---

output "aurora_cluster_endpoint" {
  description = "Aurora Serverless v2 writer endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora Serverless v2 reader endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

# --- Cache ---

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

# --- Messaging ---

output "sqs_orders_queue_url" {
  description = "SQS queue URL for order processing"
  value       = aws_sqs_queue.orders.url
}

output "sqs_dlq_url" {
  description = "SQS dead letter queue URL (check for failed orders)"
  value       = aws_sqs_queue.orders_dlq.url
}

output "sns_topic_arn" {
  description = "SNS topic ARN for order notifications"
  value       = aws_sns_topic.order_notifications.arn
}

# --- Uploads ---

output "uploads_bucket" {
  description = "S3 bucket for file uploads"
  value       = aws_s3_bucket.uploads.id
}

# --- Security ---

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

# --- Lambda Functions ---

output "lambda_get_products" {
  description = "Get products Lambda function name"
  value       = aws_lambda_function.get_products.function_name
}

output "lambda_create_order" {
  description = "Create order Lambda function name"
  value       = aws_lambda_function.create_order.function_name
}

output "lambda_process_payment" {
  description = "Process payment Lambda function name"
  value       = aws_lambda_function.process_payment.function_name
}

# --- Monitoring ---

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names for monitoring"
  value = [
    aws_cloudwatch_metric_alarm.api_5xx.alarm_name,
    aws_cloudwatch_metric_alarm.dlq_messages.alarm_name,
    aws_cloudwatch_metric_alarm.aurora_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.lambda_errors.alarm_name,
  ]
}
