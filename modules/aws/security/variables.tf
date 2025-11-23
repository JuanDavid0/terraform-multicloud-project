variable "project_name" {
  description = "Nombre base para los recursos de seguridad"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se crearán los security groups"
  type        = string
}
