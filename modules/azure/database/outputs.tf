output "cosmos_account_endpoint" {
  description = "Endpoint de Cosmos DB"
  value       = azurerm_cosmosdb_account.cosmos_acc.endpoint
}

output "cosmos_account_primary_key" {
  description = "Clave primaria de Cosmos DB"
  value       = azurerm_cosmosdb_account.cosmos_acc.primary_key
  sensitive   = true
}

output "cosmos_database_name" {
  description = "Nombre de la base de datos Cosmos"
  value       = azurerm_cosmosdb_sql_database.cosmos_db.name
}

output "cosmos_container_name" {
  description = "Nombre del container Cosmos"
  value       = azurerm_cosmosdb_sql_container.cosmos_container.name
}
