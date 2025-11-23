# ---------------------------------------------------------
# AZURE DATABASE MODULE  
# Cosmos DB para replicación desde DynamoDB
# ---------------------------------------------------------

# Sufijo aleatorio para nombre único
resource "random_string" "cosmos_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ---------------------------------------------------------
# COSMOS DB ACCOUNT
# ---------------------------------------------------------
resource "azurerm_cosmosdb_account" "cosmos_acc" {
  name                = "cosmos-${lower(var.project_name)}-${random_string.cosmos_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

# ---------------------------------------------------------
# COSMOS DB SQL DATABASE
# ---------------------------------------------------------
resource "azurerm_cosmosdb_sql_database" "cosmos_db" {
  name                = "ReplicaDB"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos_acc.name
}

# ---------------------------------------------------------
# COSMOS DB SQL CONTAINER
# ---------------------------------------------------------
resource "azurerm_cosmosdb_sql_container" "cosmos_container" {
  name                = "TablaUsuariosReplica"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos_acc.name
  database_name       = azurerm_cosmosdb_sql_database.cosmos_db.name

  partition_key_paths = ["/id"]
  throughput          = 400
}
