variable "project_name" {
  description = "Nombre base para los recursos de base de datos"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del Resource Group de Azure"
  type        = string
}

variable "location" {
  description = "Ubicación de Azure"
  type        = string
}
