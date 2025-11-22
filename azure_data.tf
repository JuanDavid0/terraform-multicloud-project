# ---------------------------------------------------------
# RANDOM ID PARA AZURE
# Al igual que en AWS S3, los nombres de Storage y Cosmos 
# deben ser únicos globalmente.
# ---------------------------------------------------------
resource "random_string" "azure_suffix" {
  length  = 6
  special = false
  upper   = false # Azure prefiere todo en minúsculas
}

# ---------------------------------------------------------
# 1. STORAGE ACCOUNT (Equivalente al Bucket S3)
# ---------------------------------------------------------
resource "azurerm_storage_account" "azure_sa" {
  name                     = "st${lower(var.proyecto_nombre)}${random_string.azure_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg_azure.name
  location                 = azurerm_resource_group.rg_azure.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # LRS = Local (Más barato), GRS = Global

  tags = {
    environment = "RetoFinal"
  }
}

# CONTENEDOR (La carpeta dentro del Storage Account)
resource "azurerm_storage_container" "azure_container" {
  name                  = "replica-archivos"
  storage_account_name  = azurerm_storage_account.azure_sa.name
  container_access_type = "private" # Privado, igual que tu S3
}

# ---------------------------------------------------------
# 2. COSMOS DB ACCOUNT (Equivalente a DynamoDB)
# Es el "servidor" de base de datos.
# ---------------------------------------------------------
resource "azurerm_cosmosdb_account" "cosmos_acc" {
  name                = "cosmos-${lower(var.proyecto_nombre)}-${random_string.azure_suffix.result}"
  location            = azurerm_resource_group.rg_azure.location
  resource_group_name = azurerm_resource_group.rg_azure.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB" # Usamos la API SQL (Compatible con JSON)

  consistency_policy {
    consistency_level = "Session" # Balance ideal entre consistencia y velocidad
  }

  # Configuración de replicación geográfica (Requerido por Azure)
  geo_location {
    location          = azurerm_resource_group.rg_azure.location
    failover_priority = 0
  }
}

# BASE DE DATOS SQL (Lógica)
resource "azurerm_cosmosdb_sql_database" "cosmos_db" {
  name                = "ReplicaDB"
  resource_group_name = azurerm_resource_group.rg_azure.name
  account_name        = azurerm_cosmosdb_account.cosmos_acc.name
}

# CONTENEDOR SQL (Equivalente a la Tabla DynamoDB)
resource "azurerm_cosmosdb_sql_container" "cosmos_container" {
  name                = "TablaUsuariosReplica"
  resource_group_name = azurerm_resource_group.rg_azure.name
  account_name        = azurerm_cosmosdb_account.cosmos_acc.name
  database_name       = azurerm_cosmosdb_sql_database.cosmos_db.name
  
  # Clave de partición: Debe coincidir conceptualmente con la Partition Key de Dynamo
  partition_key_paths = ["/id"]
  throughput          = 400 # Unidades de solicitud mínimas (Costos bajos)
}