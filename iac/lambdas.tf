# ── SECURITY GROUPS ───────────────────────────────────────────────────────────

resource "aws_security_group" "upload_lambda" {
  name   = "image-processor-${terraform.workspace}-sg-upload-lambda"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "image-processor-${terraform.workspace}-sg-upload-lambda"
  }
}

resource "aws_security_group" "crop_lambda" {
  name   = "image-processor-${terraform.workspace}-sg-crop-lambda"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "image-processor-${terraform.workspace}-sg-crop-lambda"
  }
}

# ── UPLOAD LAMBDA ─────────────────────────────────────────────────────────────

data "archive_file" "upload" {
  type        = "zip"
  source_dir  = "../lambdas/upload"
  output_path = "../lambdas/upload/function.zip"
}

resource "aws_lambda_function" "upload" {
  function_name    = "image-processor-${terraform.workspace}-upload"
  filename         = data.archive_file.upload.output_path
  source_code_hash = data.archive_file.upload.output_base64sha256
  role             = aws_iam_role.upload_lambda.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  memory_size      = var.config[terraform.workspace].lambda_memory_upload
  timeout          = var.config[terraform.workspace].lambda_timeout_upload

  environment {
    variables = {
      S3_BUCKET     = aws_s3_bucket.images.bucket
      UPLOAD_PREFIX = "uploads"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.upload_lambda.id]
  }

  tags = {
    Name = "image-processor-${terraform.workspace}-upload"
  }
}

# ── CROP LAMBDA ───────────────────────────────────────────────────────────────

data "archive_file" "crop" {
  type        = "zip"
  source_dir  = "../lambdas/crop"
  output_path = "../lambdas/crop/function.zip"
}

resource "aws_lambda_function" "crop" {
  function_name    = "image-processor-${terraform.workspace}-crop"
  filename         = data.archive_file.crop.output_path
  source_code_hash = data.archive_file.crop.output_base64sha256
  role             = aws_iam_role.crop_lambda.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  memory_size      = var.config[terraform.workspace].lambda_memory_crop
  timeout          = var.config[terraform.workspace].lambda_timeout_crop

  environment {
    variables = {
      S3_BUCKET        = aws_s3_bucket.images.bucket
      UPLOAD_PREFIX    = "uploads"
      PROCESSED_PREFIX = "processed"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.crop_lambda.id]
  }

  tags = {
    Name = "image-processor-${terraform.workspace}-crop"
  }
}

# ── SQS TRIGGER ───────────────────────────────────────────────────────────────

resource "aws_lambda_event_source_mapping" "crop_sqs" {
  event_source_arn        = aws_sqs_queue.main.arn
  function_name           = aws_lambda_function.crop.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
}