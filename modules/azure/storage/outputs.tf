output "storage_account_name" {
  description = "Nombre de la Storage Account"
  value       = azurerm_storage_account.azure_sa.name
}

output "storage_account_primary_connection_string" {
  description = "Connection string de la Storage Account"
  value       = azurerm_storage_account.azure_sa.primary_connection_string
  sensitive   = true
}

output "container_name" {
  description = "Nombre del container de almacenamiento"
  value       = azurerm_storage_container.azure_container.name
}
