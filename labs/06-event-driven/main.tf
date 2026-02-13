# =============================================================================
# Lab 06: Event-Driven Architecture
# S3 -> EventBridge -> SNS -> SQS (fan-out) -> Lambda consumers
# API Gateway -> SQS (direct integration) -> Lambda consumer
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project_name
      Lab       = "06-event-driven"
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  account_id  = data.aws_caller_identity.current.account_id
  region      = data.aws_region.current.name
}

# =============================================================================
# S3 BUCKET - Event source (file uploads trigger events)
# =============================================================================

# S3 bucket with EventBridge notifications enabled
resource "aws_s3_bucket" "uploads" {
  bucket = "${local.name_prefix}-uploads-${local.account_id}"

  tags = {
    Name = "${local.name_prefix}-uploads"
  }
}

# Enable EventBridge notifications on the S3 bucket
resource "aws_s3_bucket_notification" "uploads" {
  bucket      = aws_s3_bucket.uploads.id
  eventbridge = true
}

# =============================================================================
# EVENTBRIDGE - Captures S3 PutObject events and routes them
# =============================================================================

# EventBridge rule matching S3 PutObject events from our bucket
resource "aws_cloudwatch_event_rule" "s3_upload" {
  name        = "${local.name_prefix}-s3-upload-rule"
  description = "Capture S3 PutObject events from the uploads bucket"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.uploads.id]
      }
    }
  })

  tags = {
    Name = "${local.name_prefix}-s3-upload-rule"
  }
}

# EventBridge target: send matching events to SNS topic
resource "aws_cloudwatch_event_target" "sns" {
  rule = aws_cloudwatch_event_rule.s3_upload.name
  arn  = aws_sns_topic.file_events.arn
}

# =============================================================================
# SNS TOPIC - Fan-out: distributes events to multiple SQS queues
# =============================================================================

# SNS topic for file upload events
resource "aws_sns_topic" "file_events" {
  name = "${local.name_prefix}-file-events"

  tags = {
    Name = "${local.name_prefix}-file-events"
  }
}

# Allow EventBridge to publish to SNS topic
resource "aws_sns_topic_policy" "file_events" {
  arn = aws_sns_topic.file_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.file_events.arn
      }
    ]
  })
}

# =============================================================================
# SQS QUEUES - Message consumers with dead-letter queues
# =============================================================================

# --- Image Processing Queue ---

# Dead-letter queue for failed image processing messages
resource "aws_sqs_queue" "image_processor_dlq" {
  name                      = "${local.name_prefix}-image-processor-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name = "${local.name_prefix}-image-processor-dlq"
  }
}

# Main queue for image processing
resource "aws_sqs_queue" "image_processor" {
  name                       = "${local.name_prefix}-image-processor"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400 # 1 day

  # Send failed messages to dead-letter queue after 3 attempts
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.image_processor_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${local.name_prefix}-image-processor"
  }
}

# --- Audit Logging Queue ---

# Dead-letter queue for failed audit logging messages
resource "aws_sqs_queue" "audit_logger_dlq" {
  name                      = "${local.name_prefix}-audit-logger-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name = "${local.name_prefix}-audit-logger-dlq"
  }
}

# Main queue for audit logging
resource "aws_sqs_queue" "audit_logger" {
  name                       = "${local.name_prefix}-audit-logger"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400 # 1 day

  # Send failed messages to dead-letter queue after 3 attempts
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.audit_logger_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${local.name_prefix}-audit-logger"
  }
}

# --- API Messages Queue (for API Gateway direct integration) ---

# Dead-letter queue for API messages
resource "aws_sqs_queue" "api_messages_dlq" {
  name                      = "${local.name_prefix}-api-messages-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name = "${local.name_prefix}-api-messages-dlq"
  }
}

# Queue for messages sent via API Gateway
resource "aws_sqs_queue" "api_messages" {
  name                       = "${local.name_prefix}-api-messages"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.api_messages_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = "${local.name_prefix}-api-messages"
  }
}

# --- SQS Queue Policies: Allow SNS to send messages ---

# Policy allowing SNS topic to send messages to image processor queue
resource "aws_sqs_queue_policy" "image_processor" {
  queue_url = aws_sqs_queue.image_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSMessages"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.image_processor.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.file_events.arn
          }
        }
      }
    ]
  })
}

# Policy allowing SNS topic to send messages to audit logger queue
resource "aws_sqs_queue_policy" "audit_logger" {
  queue_url = aws_sqs_queue.audit_logger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSNSMessages"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.audit_logger.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.file_events.arn
          }
        }
      }
    ]
  })
}

# Policy allowing API Gateway to send messages to API messages queue
resource "aws_sqs_queue_policy" "api_messages" {
  queue_url = aws_sqs_queue.api_messages.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAPIGateway"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.api_messages.arn
      }
    ]
  })
}

# --- SNS Subscriptions: Subscribe SQS queues to SNS topic ---

# Subscribe image processor queue to SNS topic
resource "aws_sns_topic_subscription" "image_processor" {
  topic_arn = aws_sns_topic.file_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.image_processor.arn

  # Raw message delivery sends the original event without SNS envelope
  raw_message_delivery = true
}

# Subscribe audit logger queue to SNS topic
resource "aws_sns_topic_subscription" "audit_logger" {
  topic_arn = aws_sns_topic.file_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.audit_logger.arn

  raw_message_delivery = true
}

# =============================================================================
# LAMBDA FUNCTIONS - Event consumers
# =============================================================================

# --- Package Lambda code ---

# Zip the image processor Lambda function
data "archive_file" "image_processor" {
  type        = "zip"
  source_file = "${path.module}/lambda/image_processor.py"
  output_path = "${path.module}/lambda/image_processor.zip"
}

# Zip the audit logger Lambda function
data "archive_file" "audit_logger" {
  type        = "zip"
  source_file = "${path.module}/lambda/audit_logger.py"
  output_path = "${path.module}/lambda/audit_logger.zip"
}

# --- IAM Role for Lambda functions ---

# IAM role assumed by Lambda functions
resource "aws_iam_role" "lambda_execution" {
  name = "${local.name_prefix}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-lambda-execution-role"
  }
}

# Attach basic Lambda execution policy (CloudWatch Logs access)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy allowing Lambda to read from SQS queues
resource "aws_iam_role_policy" "lambda_sqs" {
  name = "${local.name_prefix}-lambda-sqs-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.image_processor.arn,
          aws_sqs_queue.audit_logger.arn,
          aws_sqs_queue.api_messages.arn
        ]
      }
    ]
  })
}

# --- Lambda Functions ---

# CloudWatch log group for image processor Lambda
resource "aws_cloudwatch_log_group" "image_processor" {
  name              = "/aws/lambda/${local.name_prefix}-image-processor"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-image-processor-logs"
  }
}

# Image processor Lambda function
resource "aws_lambda_function" "image_processor" {
  function_name    = "${local.name_prefix}-image-processor"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "image_processor.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.image_processor.output_path
  source_code_hash = data.archive_file.image_processor.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [aws_cloudwatch_log_group.image_processor]

  tags = {
    Name = "${local.name_prefix}-image-processor"
  }
}

# SQS event source mapping: triggers image processor Lambda from SQS queue
resource "aws_lambda_event_source_mapping" "image_processor" {
  event_source_arn = aws_sqs_queue.image_processor.arn
  function_name    = aws_lambda_function.image_processor.arn
  batch_size       = 10
  enabled          = true
}

# CloudWatch log group for audit logger Lambda
resource "aws_cloudwatch_log_group" "audit_logger" {
  name              = "/aws/lambda/${local.name_prefix}-audit-logger"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-audit-logger-logs"
  }
}

# Audit logger Lambda function
resource "aws_lambda_function" "audit_logger" {
  function_name    = "${local.name_prefix}-audit-logger"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "audit_logger.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.audit_logger.output_path
  source_code_hash = data.archive_file.audit_logger.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [aws_cloudwatch_log_group.audit_logger]

  tags = {
    Name = "${local.name_prefix}-audit-logger"
  }
}

# SQS event source mapping: triggers audit logger Lambda from SQS queue
resource "aws_lambda_event_source_mapping" "audit_logger" {
  event_source_arn = aws_sqs_queue.audit_logger.arn
  function_name    = aws_lambda_function.audit_logger.arn
  batch_size       = 10
  enabled          = true
}

# CloudWatch log group for API message consumer Lambda
resource "aws_cloudwatch_log_group" "api_consumer" {
  name              = "/aws/lambda/${local.name_prefix}-api-consumer"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-api-consumer-logs"
  }
}

# API message consumer Lambda (reuses audit_logger code for simplicity)
resource "aws_lambda_function" "api_consumer" {
  function_name    = "${local.name_prefix}-api-consumer"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "audit_logger.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.audit_logger.output_path
  source_code_hash = data.archive_file.audit_logger.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
      SOURCE      = "api-gateway"
    }
  }

  depends_on = [aws_cloudwatch_log_group.api_consumer]

  tags = {
    Name = "${local.name_prefix}-api-consumer"
  }
}

# SQS event source mapping: triggers API consumer Lambda from API messages queue
resource "aws_lambda_event_source_mapping" "api_consumer" {
  event_source_arn = aws_sqs_queue.api_messages.arn
  function_name    = aws_lambda_function.api_consumer.arn
  batch_size       = 10
  enabled          = true
}

# =============================================================================
# API GATEWAY - Direct SQS integration (no Lambda proxy)
# =============================================================================

# REST API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name        = "${local.name_prefix}-api"
  description = "API Gateway with direct SQS integration"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

# /messages resource
resource "aws_api_gateway_resource" "messages" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "messages"
}

# IAM role for API Gateway to send messages to SQS
resource "aws_iam_role" "api_gateway_sqs" {
  name = "${local.name_prefix}-apigw-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-apigw-sqs-role"
  }
}

# Policy allowing API Gateway role to send messages to SQS
resource "aws_iam_role_policy" "api_gateway_sqs" {
  name = "${local.name_prefix}-apigw-sqs-policy"
  role = aws_iam_role.api_gateway_sqs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.api_messages.arn
      }
    ]
  })
}

# POST method on /messages: direct integration with SQS (no Lambda proxy!)
resource "aws_api_gateway_method" "post_message" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration: API Gateway -> SQS (AWS service integration)
resource "aws_api_gateway_integration" "sqs" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.messages.id
  http_method             = aws_api_gateway_method.post_message.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  credentials             = aws_iam_role.api_gateway_sqs.arn

  # SQS SendMessage API endpoint
  uri = "arn:aws:apigateway:${local.region}:sqs:path/${local.account_id}/${aws_sqs_queue.api_messages.name}"

  # Transform the request body into SQS SendMessage parameters
  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

# Method response for 200 OK
resource "aws_api_gateway_method_response" "post_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.post_message.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Integration response mapping
resource "aws_api_gateway_integration_response" "sqs_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.post_message.http_method
  status_code = aws_api_gateway_method_response.post_200.status_code

  response_templates = {
    "application/json" = <<EOF
{
  "message": "Message sent to queue successfully",
  "requestId": "$context.requestId"
}
EOF
  }

  depends_on = [aws_api_gateway_integration.sqs]
}

# Deploy the API
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Redeploy when any API resource changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.messages.id,
      aws_api_gateway_method.post_message.id,
      aws_api_gateway_integration.sqs.id,
      aws_api_gateway_method_response.post_200.id,
      aws_api_gateway_integration_response.sqs_200.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  tags = {
    Name = "${local.name_prefix}-api-stage"
  }
}
