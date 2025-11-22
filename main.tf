# ---------------------------------------------------------
# 1. LADO AWS: VPC (Red Virtual)
# ---------------------------------------------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.proyecto_nombre}-VPC"
  }
}

# ---------------------------------------------------------
# 2. LADO AZURE: Resource Group
# ---------------------------------------------------------
resource "azurerm_resource_group" "rg_azure" {
  name     = "${var.proyecto_nombre}-RG"
  location = var.azure_location
}