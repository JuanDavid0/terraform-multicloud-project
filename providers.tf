# Bloque de configuración de Terraform
terraform {
  required_providers {
    # Definimos el proveedor de AWS
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Definimos el proveedor de Azure (Azure Resource Manager)
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

# Configuración del Proveedor AWS
provider "aws" {
  region = var.aws_region
}

# Configuración del Proveedor Azure
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}