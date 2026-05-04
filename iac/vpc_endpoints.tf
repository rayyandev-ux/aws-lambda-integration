# ── S3 GATEWAY ENDPOINT ───────────────────────────────────────────────────────

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_a.id,
    aws_route_table.private_b.id,
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:PutObject"]
        Resource  = "${aws_s3_bucket.images.arn}/*"
      }
    ]
  })

  tags = {
    Name = "image-processor-${terraform.workspace}-vpce-s3"
  }
}

# ── SQS INTERFACE ENDPOINT ────────────────────────────────────────────────────

resource "aws_security_group" "vpce_sqs" {
  name   = "image-processor-${terraform.workspace}-sg-vpce-sqs"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.upload_lambda.id, aws_security_group.crop_lambda.id]
  }

  tags = {
    Name = "image-processor-${terraform.workspace}-sg-vpce-sqs"
  }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.sqs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id,
  ]

  security_group_ids = [aws_security_group.vpce_sqs.id]

  tags = {
    Name = "image-processor-${terraform.workspace}-vpce-sqs"
  }
}