variable "project_name" {
  description = "Nombre base para los recursos de networking"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango CIDR para la VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDRs para las subredes públicas"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs para las subredes privadas"
  type        = list(string)
}
