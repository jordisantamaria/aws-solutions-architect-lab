# =============================================================================
# Lab 07: Data Pipeline - Streaming and Batch Processing
# =============================================================================
# Architecture: Kinesis Data Streams -> Firehose -> S3 (data lake)
#               Kinesis Data Streams -> Lambda (real-time processing)
#               S3 + Glue Catalog -> Athena (SQL queries)
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

# Current account ID for unique naming
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# =============================================================================
# Kinesis Data Stream
# =============================================================================
# Main ingestion point for streaming data. Producers send records here,
# which are then consumed by both Firehose (batch to S3) and Lambda (real-time).

resource "aws_kinesis_stream" "data_stream" {
  name             = "${var.project_name}-data-stream"
  shard_count      = var.shard_count
  retention_period = 24 # Hours to retain data in the stream

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Project = var.project_name
    Lab     = "07-data-pipeline"
  }
}

# =============================================================================
# S3 Bucket - Data Lake
# =============================================================================
# Central storage for all pipeline data. Firehose delivers raw data here.
# Lifecycle policy moves data to Infrequent Access after 30 days.

resource "aws_s3_bucket" "data_lake" {
  bucket        = "${var.project_name}-data-lake-${local.account_id}"
  force_destroy = true # Allow terraform destroy even with objects

  tags = {
    Project = var.project_name
    Lab     = "07-data-pipeline"
  }
}

# Enable versioning for data integrity
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy: transition to IA after 30 days to save costs
resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Move to Glacier after 90 days for long-term archival
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# Block public access to the data lake bucket
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# S3 Bucket - Athena Query Results
# =============================================================================

resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.project_name}-athena-results-${local.account_id}"
  force_destroy = true

  tags = {
    Project = var.project_name
    Lab     = "07-data-pipeline"
  }
}

resource "aws_s3_bucket_public_access_block" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# IAM Role - Kinesis Firehose
# =============================================================================
# Firehose needs permissions to read from Kinesis and write to S3.

resource "aws_iam_role" "firehose_role" {
  name = "${var.project_name}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
    Lab     = "07-data-pipeline"
  }
}

# Policy: Allow Firehose to write to S3 data lake bucket
resource "aws_iam_role_policy" "firehose_s3_policy" {
  name = "${var.project_name}-firehose-s3"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      }
    ]
  })
}

# Policy: Allow Firehose to read from the Kinesis stream
resource "aws_iam_role_policy" "firehose_kinesis_policy" {
  name = "${var.project_name}-firehose-kinesis"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.data_stream.arn
      }
    ]
  })
}

# =============================================================================
# Kinesis Data Firehose Delivery Stream
# =============================================================================
# Reads from Kinesis Data Stream and delivers batches to S3.
# Buffer configuration: delivers when 1MB is accumulated OR 60 seconds pass.

resource "aws_kinesis_firehose_delivery_stream" "s3_delivery" {
  name        = "${var.project_name}-s3-delivery"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.data_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.data_lake.arn

    # Prefix for organizing data by date (Hive-compatible partitioning)
    prefix              = "raw/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/"

    # Buffer configuration: deliver when either condition is met
    buffering_size     = 1   # MB - deliver when 1MB accumulated
    buffering_interval = 60  # seconds - or every 60 seconds

    # Compression for cost savings
    compression_format = "GZIP"
  }

  tags = {
    Project = var.project_name
    Lab     = "07-data-pipeline"
  }
}

# =============================================================================
# Lambda Function - Stream Processor (Real-time)
# =============================================================================
# Processes Kinesis records in real-time. Triggered by new records in the stream.

# Package the Lambda function code
data "archive_file" "stream_processor" {
  type        = "zip"
  source_file = "${path.module}/lambda/stream_processor.py"
  output_path = "${path.module}/lambda/stream_processor.zip"
}

# IAM Role for the Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-stream-processor-role"

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
    Lab     = "07-data-pipeline"
  }
}

# Policy: Allow Lambda to read from Kinesis stream
resource "aws_iam_role_policy" "lambda_kinesis_policy" {
  name = "${var.project_name}-lambda-kinesis"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:DescribeStreamSummary",
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:ListShards",
          "kinesis:ListStreams",
          "kinesis:SubscribeToShard"
        ]
        Resource = aws_kinesis_stream.data_stream.arn
      }
    ]
  })
}

# Policy: Allow Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function definition
resource "aws_lambda_function" "stream_processor" {
  filename         = data.archive_file.stream_processor.output_path
  function_name    = "${var.project_name}-stream-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "stream_processor.handler"
  source_code_hash = data.archive_file.stream_processor.output_base64sha256
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 128

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = "lab"
    }
  }

  tags = {
    Project = var.project_name
    Lab     = "07-data-pipeline"
  }
}

# Event source mapping: trigger Lambda from Kinesis stream
resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.data_stream.arn
  function_name     = aws_lambda_function.stream_processor.arn
  starting_position = "LATEST"

  # Process up to 100 records per batch
  batch_size                         = 100
  maximum_batching_window_in_seconds = 10

  # Retry configuration
  maximum_retry_attempts       = 3
  bisect_batch_on_function_error = true
}

# CloudWatch Log Group for the Lambda function
resource "aws_cloudwatch_log_group" "stream_processor" {
  name              = "/aws/lambda/${aws_lambda_function.stream_processor.function_name}"
  retention_in_days = 7

  tags = {
    Project = var.project_name
    Lab     = "07-data-pipeline"
  }
}

# =============================================================================
# AWS Glue Catalog - Database and Table
# =============================================================================
# Defines the schema for data in S3 so Athena can query it with SQL.
# Acts as a central metadata repository (similar to Hive metastore).

resource "aws_glue_catalog_database" "sensor_data" {
  name = "${replace(var.project_name, "-", "_")}_sensor_db"

  description = "Database for sensor data from the Kinesis pipeline"
}

# Glue table defines the schema and S3 location for Athena queries
resource "aws_glue_catalog_table" "sensor_data" {
  name          = "sensor_data"
  database_name = aws_glue_catalog_database.sensor_data.name

  description = "Raw sensor data delivered by Kinesis Firehose"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"  = "json"
    "compressionType" = "gzip"
    EXTERNAL          = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_lake.id}/raw/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    # Define columns matching the sensor data schema
    columns {
      name = "sensor_id"
      type = "string"
    }

    columns {
      name = "temperature"
      type = "double"
    }

    columns {
      name = "humidity"
      type = "double"
    }

    columns {
      name = "timestamp"
      type = "string"
    }

    columns {
      name = "location"
      type = "string"
    }
  }

  # Partition keys for efficient querying by date
  partition_keys {
    name = "year"
    type = "string"
  }

  partition_keys {
    name = "month"
    type = "string"
  }

  partition_keys {
    name = "day"
    type = "string"
  }
}

# =============================================================================
# Amazon Athena Workgroup
# =============================================================================
# Configures Athena with a dedicated workgroup and results location.

resource "aws_athena_workgroup" "main" {
  name = "${var.project_name}-workgroup"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.id}/results/"
    }
  }

  tags = {
    Project = var.project_name
    Lab     = "07-data-pipeline"
  }
}
