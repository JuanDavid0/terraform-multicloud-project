output "dynamo_sync_lambda_arn" {
  description = "ARN de la Lambda de sincronización DynamoDB"
  value       = aws_lambda_function.dynamo_sync.arn
}

output "s3_sync_lambda_arn" {
  description = "ARN de la Lambda de sincronización S3"
  value       = aws_lambda_function.s3_sync.arn
}

output "lambda_role_arn" {
  description = "ARN del IAM role de las Lambdas"
  value       = aws_iam_role.lambda_role.arn
}
