resource "aws_cloudwatch_log_group" "upload" {
  name              = "/aws/lambda/image-processor-${terraform.workspace}-upload"
  retention_in_days = var.config[terraform.workspace].log_retention
}

resource "aws_cloudwatch_log_group" "crop" {
  name              = "/aws/lambda/image-processor-${terraform.workspace}-crop"
  retention_in_days = var.config[terraform.workspace].log_retention
}

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/image-processor-${terraform.workspace}"
  retention_in_days = var.config[terraform.workspace].log_retention
}

resource "aws_sns_topic" "dlq_alarm" {
  name = "image-processor-${terraform.workspace}-dlq-alarm"
}

resource "aws_cloudwatch_metric_alarm" "dlq" {
  alarm_name          = "image-processor-${terraform.workspace}-dlq-messages-alarm"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.dlq_alarm.arn]
}