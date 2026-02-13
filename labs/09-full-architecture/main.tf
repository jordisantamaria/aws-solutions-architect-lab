# =============================================================================
# Lab 09: Full Architecture - E-Commerce Platform (Final Project)
# =============================================================================
# Architecture: Serverless e-commerce platform combining all concepts
#   - Cognito (auth) + API Gateway + Lambda (API layer)
#   - Aurora Serverless v2 (database) + ElastiCache Redis (cache/sessions)
#   - SQS (async order processing) + SNS (notifications)
#   - S3 + CloudFront (frontend hosting + CDN)
#   - WAF (security) + CloudWatch (monitoring)
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
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# =============================================================================
# VPC (for Aurora and ElastiCache which require VPC)
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name    = "${var.project_name}-private-${count.index + 1}"
    Project = var.project_name
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-${count.index + 1}"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security group for Lambda functions that need VPC access
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-lambda-"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-lambda-sg"
    Project = var.project_name
  }
}

# Security group for Aurora
resource "aws_security_group" "aurora" {
  name_prefix = "${var.project_name}-aurora-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = {
    Name    = "${var.project_name}-aurora-sg"
    Project = var.project_name
  }
}

# Security group for ElastiCache
resource "aws_security_group" "elasticache" {
  name_prefix = "${var.project_name}-redis-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = {
    Name    = "${var.project_name}-redis-sg"
    Project = var.project_name
  }
}

# =============================================================================
# Cognito User Pool - Authentication
# =============================================================================
# Manages user registration, authentication, and token issuance.
# Integrates with API Gateway as an authorizer.

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # User attributes
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  # Auto-verify email
  auto_verified_attributes = ["email"]

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Project = var.project_name
  }
}

# Cognito App Client (for frontend to authenticate)
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # Token validity
  access_token_validity  = 1  # hours
  id_token_validity      = 1  # hours
  refresh_token_validity = 30 # days

  # No client secret for public clients (SPA)
  generate_secret = false
}

# =============================================================================
# S3 + CloudFront - Frontend Hosting
# =============================================================================

# S3 bucket for frontend static files
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project_name}-frontend-${local.account_id}"
  force_destroy = true

  tags = {
    Project = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control for CloudFront to access S3
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "${var.project_name} frontend distribution"
  price_class         = "PriceClass_100" # US + Europe only to save costs

  # S3 origin
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-frontend"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # SPA: redirect 404s to index.html for client-side routing
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # WAF association
  web_acl_id = aws_wafv2_web_acl.main.arn

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project = var.project_name
  }
}

# S3 bucket policy allowing CloudFront access
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFront"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}

# =============================================================================
# S3 - File Uploads (with presigned URLs)
# =============================================================================

resource "aws_s3_bucket" "uploads" {
  bucket        = "${var.project_name}-uploads-${local.account_id}"
  force_destroy = true

  tags = {
    Project = var.project_name
  }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS configuration for browser uploads via presigned URLs
resource "aws_s3_bucket_cors_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["*"] # Restrict to your domain in production
    max_age_seconds = 3600
  }
}

# =============================================================================
# API Gateway - REST API
# =============================================================================

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api"
  description = "E-commerce API for ${var.project_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Project = var.project_name
  }
}

# Cognito authorizer for the API
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${var.project_name}-cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns   = [aws_cognito_user_pool.main.arn]
}

# --- /products resource ---
resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_method" "get_products" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "get_products" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.get_products.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_products.invoke_arn
}

# --- /orders resource ---
resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_method" "create_order" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "create_order" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.create_order.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_order.invoke_arn
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  depends_on = [
    aws_api_gateway_integration.get_products,
    aws_api_gateway_integration.create_order
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  tags = {
    Project = var.project_name
  }
}

# =============================================================================
# Lambda Functions
# =============================================================================

# --- Common IAM role for Lambda functions ---
resource "aws_iam_role" "lambda_common" {
  name = "${var.project_name}-lambda-common-role"

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
    Project = var.project_name
  }
}

# Basic execution role (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_common.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access for Lambda (to reach Aurora and ElastiCache)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_common.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Policy for SQS, SNS, and S3 access
resource "aws_iam_role_policy" "lambda_services" {
  name = "${var.project_name}-lambda-services"
  role = aws_iam_role.lambda_common.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [
          aws_sqs_queue.orders.arn,
          aws_sqs_queue.orders_dlq.arn
        ]
      },
      {
        Sid    = "SNSAccess"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.order_notifications.arn
      },
      {
        Sid    = "S3UploadsAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      }
    ]
  })
}

# --- get_products Lambda ---
data "archive_file" "get_products" {
  type        = "zip"
  source_file = "${path.module}/lambda/get_products.py"
  output_path = "${path.module}/lambda/get_products.zip"
}

resource "aws_lambda_function" "get_products" {
  filename         = data.archive_file.get_products.output_path
  function_name    = "${var.project_name}-get-products"
  role             = aws_iam_role.lambda_common.arn
  handler          = "get_products.handler"
  source_code_hash = data.archive_file.get_products.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST        = aws_rds_cluster.main.endpoint
      DB_NAME        = var.db_name
      REDIS_HOST     = aws_elasticache_replication_group.main.primary_endpoint_address
      REDIS_PORT     = "6379"
      PROJECT_NAME   = var.project_name
    }
  }

  tags = {
    Project  = var.project_name
    Function = "get-products"
  }
}

# Allow API Gateway to invoke get_products
resource "aws_lambda_permission" "get_products" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_products.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# --- create_order Lambda ---
data "archive_file" "create_order" {
  type        = "zip"
  source_file = "${path.module}/lambda/create_order.py"
  output_path = "${path.module}/lambda/create_order.zip"
}

resource "aws_lambda_function" "create_order" {
  filename         = data.archive_file.create_order.output_path
  function_name    = "${var.project_name}-create-order"
  role             = aws_iam_role.lambda_common.arn
  handler          = "create_order.handler"
  source_code_hash = data.archive_file.create_order.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST        = aws_rds_cluster.main.endpoint
      DB_NAME        = var.db_name
      SQS_QUEUE_URL  = aws_sqs_queue.orders.url
      PROJECT_NAME   = var.project_name
    }
  }

  tags = {
    Project  = var.project_name
    Function = "create-order"
  }
}

# Allow API Gateway to invoke create_order
resource "aws_lambda_permission" "create_order" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# --- process_payment Lambda (triggered by SQS) ---
data "archive_file" "process_payment" {
  type        = "zip"
  source_file = "${path.module}/lambda/process_payment.py"
  output_path = "${path.module}/lambda/process_payment.zip"
}

resource "aws_lambda_function" "process_payment" {
  filename         = data.archive_file.process_payment.output_path
  function_name    = "${var.project_name}-process-payment"
  role             = aws_iam_role.lambda_common.arn
  handler          = "process_payment.handler"
  source_code_hash = data.archive_file.process_payment.output_base64sha256
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST          = aws_rds_cluster.main.endpoint
      DB_NAME          = var.db_name
      SNS_TOPIC_ARN    = aws_sns_topic.order_notifications.arn
      PROJECT_NAME     = var.project_name
    }
  }

  tags = {
    Project  = var.project_name
    Function = "process-payment"
  }
}

# SQS trigger for process_payment Lambda
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.orders.arn
  function_name    = aws_lambda_function.process_payment.arn
  batch_size       = 10
  enabled          = true
}

# CloudWatch Log Groups for all Lambda functions
resource "aws_cloudwatch_log_group" "get_products" {
  name              = "/aws/lambda/${aws_lambda_function.get_products.function_name}"
  retention_in_days = 7
  tags = { Project = var.project_name }
}

resource "aws_cloudwatch_log_group" "create_order" {
  name              = "/aws/lambda/${aws_lambda_function.create_order.function_name}"
  retention_in_days = 7
  tags = { Project = var.project_name }
}

resource "aws_cloudwatch_log_group" "process_payment" {
  name              = "/aws/lambda/${aws_lambda_function.process_payment.function_name}"
  retention_in_days = 7
  tags = { Project = var.project_name }
}

# =============================================================================
# Aurora Serverless v2 (PostgreSQL)
# =============================================================================
# Scales automatically between 0.5 and 2 ACUs based on demand.
# Perfect for variable workloads like an e-commerce platform.

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name    = "${var.project_name}-db-subnet"
    Project = var.project_name
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier     = "${var.project_name}-aurora-cluster"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "15.4"
  database_name          = var.db_name
  master_username        = "dbadmin"
  master_password        = "ChangeMe123!" # Use Secrets Manager in production
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.aurora.id]
  skip_final_snapshot    = true

  # Serverless v2 scaling configuration
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2.0
  }

  tags = {
    Project = var.project_name
  }
}

# Aurora Serverless v2 instance
resource "aws_rds_cluster_instance" "main" {
  identifier           = "${var.project_name}-aurora-instance-1"
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.main.engine
  engine_version       = aws_rds_cluster.main.engine_version
  db_subnet_group_name = aws_db_subnet_group.main.name

  tags = {
    Project = var.project_name
  }
}

# =============================================================================
# ElastiCache Redis (Sessions + Cache)
# =============================================================================
# Used for caching product queries and storing user sessions.

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-redis-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Project = var.project_name
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis for ${var.project_name} - sessions and cache"

  node_type            = "cache.t3.micro"
  num_cache_clusters   = 1 # Single node for lab (use 2+ for production HA)
  port                 = 6379
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]

  # No Multi-AZ for lab cost savings
  automatic_failover_enabled = false

  tags = {
    Project = var.project_name
  }
}

# =============================================================================
# SQS - Order Processing Queue + Dead Letter Queue
# =============================================================================

# Dead letter queue for failed order processing
resource "aws_sqs_queue" "orders_dlq" {
  name                      = "${var.project_name}-orders-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Project = var.project_name
  }
}

# Main order processing queue
resource "aws_sqs_queue" "orders" {
  name                       = "${var.project_name}-orders"
  visibility_timeout_seconds = 120 # Must be >= Lambda timeout
  message_retention_seconds  = 86400  # 1 day
  receive_wait_time_seconds  = 10     # Long polling

  # Dead letter queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orders_dlq.arn
    maxReceiveCount     = 3 # Move to DLQ after 3 failed attempts
  })

  tags = {
    Project = var.project_name
  }
}

# =============================================================================
# SNS - Order Notifications
# =============================================================================

resource "aws_sns_topic" "order_notifications" {
  name = "${var.project_name}-order-notifications"

  tags = {
    Project = var.project_name
  }
}

# Example email subscription (for testing)
# Uncomment and set your email to receive notifications
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.order_notifications.arn
#   protocol  = "email"
#   endpoint  = "your-email@example.com"
# }

# =============================================================================
# WAF - Web Application Firewall
# =============================================================================
# Protects CloudFront and API Gateway from common web attacks.

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.project_name}-waf"
  description = "WAF for ${var.project_name} e-commerce platform"
  scope       = "CLOUDFRONT"

  # Must be in us-east-1 for CloudFront WAF
  provider = aws

  default_action {
    allow {}
  }

  # Rule 1: AWS Managed Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: SQL Injection protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-sqli-rules"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Rate limiting (prevent DDoS/abuse)
  rule {
    name     = "RateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000 # Requests per 5 minutes per IP
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Project = var.project_name
  }
}

# =============================================================================
# CloudWatch Alarms
# =============================================================================

# Alarm: API Gateway 5xx errors
resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${var.project_name}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300 # 5 minutes
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API Gateway is returning too many 5xx errors"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.main.name
    Stage   = var.environment
  }

  tags = {
    Project = var.project_name
  }
}

# Alarm: SQS DLQ has messages (orders failing)
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project_name}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Dead letter queue has messages - order processing failures"

  dimensions = {
    QueueName = aws_sqs_queue.orders_dlq.name
  }

  tags = {
    Project = var.project_name
  }
}

# Alarm: Aurora CPU high
resource "aws_cloudwatch_metric_alarm" "aurora_cpu" {
  alarm_name          = "${var.project_name}-aurora-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Aurora CPU utilization is above 80%"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }

  tags = {
    Project = var.project_name
  }
}

# Alarm: Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda functions are throwing too many errors"

  dimensions = {
    FunctionName = aws_lambda_function.process_payment.function_name
  }

  tags = {
    Project = var.project_name
  }
}
