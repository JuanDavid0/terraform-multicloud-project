# --- Variables Generales ---
variable "proyecto_nombre" {
  description = "Nombre base para los recursos"
  type        = string
  default     = "RetoFinalCloud"
}

# --- Variables AWS ---
variable "aws_region" {
  description = "Región donde se desplegará AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "Rango de IP para la VPC de AWS"
  default     = "10.0.0.0/16"
}

# --- Variables Azure ---
variable "azure_location" {
  description = "Ubicación para los recursos de Azure"
  type        = string
  default     = "West US" # Cercano a us-east-1 para menor latencia
}

# --- Variables de Red ---
variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR para las subredes públicas (Donde va el Load Balancer)"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR para las subredes privadas (Donde van los Microservicios, DB y Lambdas)"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}