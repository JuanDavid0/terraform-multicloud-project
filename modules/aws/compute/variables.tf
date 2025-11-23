variable "project_name" {
  description = "Nombre base para los recursos de compute"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "ecr_repository_count" {
  description = "Número de repositorios ECR a crear"
  type        = number
  default     = 3
}

variable "container_image" {
  description = "Imagen Docker temporal para la task definition"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subredes privadas para ECS"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "ID del Security Group para ECS"
  type        = string
}

variable "target_group_arn" {
  description = "ARN del Target Group del ALB"
  type        = string
}
