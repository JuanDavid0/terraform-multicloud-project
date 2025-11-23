# ---------------------------------------------------------
# OUTPUTS PRINCIPALES
# ---------------------------------------------------------

# --- AWS OUTPUTS ---

output "alb_dns_name" {
  description = "La URL pública para acceder a tus microservicios"
  value       = module.aws_alb.alb_dns_name
}

output "ecr_repo_urls" {
  description = "URLs de los repositorios ECR para subir imágenes Docker"
  value       = module.aws_compute.ecr_repository_urls
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.aws_networking.vpc_id
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  value       = module.aws_database.dynamodb_table_name
}

output "s3_bucket_name" {
  description = "Nombre del bucket S3"
  value       = module.aws_storage.s3_bucket_name
}

# --- AZURE OUTPUTS ---

output "azure_storage_connection_string" {
  description = "Cadena de conexión para Azure Storage"
  value       = module.azure_storage.storage_account_primary_connection_string
  sensitive   = true
}

output "azure_cosmos_endpoint" {
  description = "Endpoint de Cosmos DB"
  value       = module.azure_database.cosmos_account_endpoint
}

output "azure_cosmos_key" {
  description = "Clave primaria de Cosmos DB"
  value       = module.azure_database.cosmos_account_primary_key
  sensitive   = true
}

# --- LAMBDA OUTPUTS ---

output "dynamo_sync_lambda_arn" {
  description = "ARN de la Lambda de sincronización DynamoDB"
  value       = module.aws_lambda.dynamo_sync_lambda_arn
}

output "s3_sync_lambda_arn" {
  description = "ARN de la Lambda de sincronización S3"
  value       = module.aws_lambda.s3_sync_lambda_arn
}