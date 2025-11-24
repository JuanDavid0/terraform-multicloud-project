# AWS STORAGE MODULE
# S3 Bucket con VPC Endpoint


# Generador de sufijo aleatorio para nombre único global
resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}


# S3 BUCKET

resource "aws_s3_bucket" "main_bucket" {
  bucket        = "${lower(var.project_name)}-files-bucket-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-S3-Bucket"
  }
}


# BLOQUEO DE ACCESO PÚBLICO

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.main_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# VPC ENDPOINT para S3

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.private_route_table_id]

  tags = {
    Name = "${var.project_name}-S3-Endpoint"
  }
}
