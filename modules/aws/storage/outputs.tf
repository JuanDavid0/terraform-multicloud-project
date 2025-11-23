output "s3_bucket_id" {
  description = "ID del bucket S3"
  value       = aws_s3_bucket.main_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.main_bucket.arn
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.main_bucket.bucket
}
