# =============================================================================
# Outputs for Lab 07: Data Pipeline
# =============================================================================

output "kinesis_stream_name" {
  description = "Name of the Kinesis Data Stream (use this for the test producer)"
  value       = aws_kinesis_stream.data_stream.name
}

output "kinesis_stream_arn" {
  description = "ARN of the Kinesis Data Stream"
  value       = aws_kinesis_stream.data_stream.arn
}

output "firehose_delivery_stream_name" {
  description = "Name of the Kinesis Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.s3_delivery.name
}

output "data_lake_bucket" {
  description = "S3 bucket name for the data lake"
  value       = aws_s3_bucket.data_lake.id
}

output "data_lake_bucket_arn" {
  description = "ARN of the S3 data lake bucket"
  value       = aws_s3_bucket.data_lake.arn
}

output "athena_workgroup" {
  description = "Athena workgroup name for running queries"
  value       = aws_athena_workgroup.main.name
}

output "athena_results_bucket" {
  description = "S3 bucket for Athena query results"
  value       = aws_s3_bucket.athena_results.id
}

output "glue_database_name" {
  description = "Glue catalog database name"
  value       = aws_glue_catalog_database.sensor_data.name
}

output "glue_table_name" {
  description = "Glue catalog table name for sensor data"
  value       = aws_glue_catalog_table.sensor_data.name
}

output "lambda_function_name" {
  description = "Name of the stream processor Lambda function"
  value       = aws_lambda_function.stream_processor.function_name
}

output "test_producer_command" {
  description = "Command to run the test producer script"
  value       = "python test_producer.py --stream-name ${aws_kinesis_stream.data_stream.name} --region ${var.region}"
}
