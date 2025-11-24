
# AZURE STORAGE MODULE
# Storage Account y Container para replicación desde S3


# Sufijo aleatorio para nombre único
resource "random_string" "azure_suffix" {
  length  = 6
  special = false
  upper   = false
}


# STORAGE ACCOUNT

resource "azurerm_storage_account" "azure_sa" {
  name                     = "st${lower(var.project_name)}${random_string.azure_suffix.result}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "RetoFinal"
  }
}


# STORAGE CONTAINER

resource "azurerm_storage_container" "azure_container" {
  name                  = "replica-archivos"
  storage_account_name  = azurerm_storage_account.azure_sa.name
  container_access_type = "private"
}
