variable "project_name" {
  description = "Nombre base para los recursos Lambda"
  type        = string
}

variable "dynamo_sync_code_path" {
  description = "Ruta al código Python de sincronización DynamoDB"
  type        = string
}

variable "s3_sync_code_path" {
  description = "Ruta al código Python de sincronización S3"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subredes privadas para las Lambdas"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID del Security Group para las Lambdas"
  type        = string
}

variable "dynamodb_stream_arn" {
  description = "ARN del stream de DynamoDB"
  type        = string
}

variable "cosmos_endpoint" {
  description = "Endpoint de Cosmos DB"
  type        = string
}

variable "cosmos_primary_key" {
  description = "Clave primaria de Cosmos DB"
  type        = string
  sensitive   = true
}

variable "azure_storage_connection_string" {
  description = "Connection string de Azure Storage"
  type        = string
  sensitive   = true
}

variable "azure_storage_account_name" {
  description = "Nombre de la Storage Account de Azure"
  type        = string
}

variable "azure_container_name" {
  description = "Nombre del container de Azure Storage"
  type        = string
}

variable "s3_bucket_id" {
  description = "ID del bucket S3"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN del bucket S3"
  type        = string
}
