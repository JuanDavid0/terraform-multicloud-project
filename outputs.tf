output "alb_dns_name" {
  description = "La URL publica para acceder a tus microservicios"
  value       = aws_lb.app_alb.dns_name
}

output "ecr_repo_urls" {
  description = "URLs de los repositorios para subir tus imagenes Docker"
  value       = aws_ecr_repository.microservicios[*].repository_url
}

# --- OUTPUTS DE AZURE ---

output "azure_storage_connection_string" {
  description = "Cadena de conexión para que la Lambda escriba archivos en Azure"
  value       = azurerm_storage_account.azure_sa.primary_connection_string
  sensitive   = true # Terraform ocultará esto en pantalla por seguridad
}

output "azure_cosmos_endpoint" {
  description = "URL de la base de datos Cosmos DB"
  value       = azurerm_cosmosdb_account.cosmos_acc.endpoint
}

output "azure_cosmos_key" {
  description = "Clave maestra para escribir en Cosmos DB"
  value       = azurerm_cosmosdb_account.cosmos_acc.primary_key
  sensitive   = true
}