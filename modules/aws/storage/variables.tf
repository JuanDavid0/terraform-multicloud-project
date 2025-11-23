variable "project_name" {
  description = "Nombre base para los recursos de almacenamiento"
  type        = string
}

variable "aws_region" {
  description = "Región de AWS para el VPC endpoint"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_route_table_id" {
  description = "ID de la tabla de rutas privada para el VPC endpoint"
  type        = string
}
