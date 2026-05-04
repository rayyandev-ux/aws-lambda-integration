output "api_endpoint" {
  description = "URL del API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "s3_bucket" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.images.bucket
}

output "sqs_queue_url" {
  description = "URL de la cola SQS"
  value       = aws_sqs_queue.main.url
}

output "upload_lambda" {
  description = "Nombre del upload lambda"
  value       = aws_lambda_function.upload.function_name
}

output "crop_lambda" {
  description = "Nombre del crop lambda"
  value       = aws_lambda_function.crop.function_name
}