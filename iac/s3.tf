resource "aws_s3_bucket" "images" {
  bucket = "image-processor-${terraform.workspace}-images-${var.suffix}"

  tags = {
    Name = "image-processor-${terraform.workspace}-images-${var.suffix}"
  }
}

# ── VERSIONADO ────────────────────────────────────────────────────────────────

resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ── ENCRIPTACIÓN ──────────────────────────────────────────────────────────────

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ── ACCESO PRIVADO ────────────────────────────────────────────────────────────

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── LIFECYCLE ─────────────────────────────────────────────────────────────────

resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "expire-uploads"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = 30
    }
  }

  rule {
    id     = "expire-processed"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    expiration {
      days = 90
    }
  }
}

# ── NOTIFICACIÓN A SQS ────────────────────────────────────────────────────────

resource "aws_s3_bucket_notification" "images" {
  bucket = aws_s3_bucket.images.id

  queue {
    queue_arn     = aws_sqs_queue.main.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/"
  }
}