output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  value       = aws_dynamodb_table.main_table.name
}

output "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB"
  value       = aws_dynamodb_table.main_table.arn
}

output "dynamodb_stream_arn" {
  description = "ARN del stream de DynamoDB para triggers Lambda"
  value       = aws_dynamodb_table.main_table.stream_arn
}
