output "azure_cosmosdb_account_id" {
  value       = azurerm_cosmosdb_account.cosmosdb.id
  description = "The Cosmos DB account."
}

output "azure_cosmosdb_account_name" {
  value       = azurerm_cosmosdb_account.cosmosdb.name
  description = "The Cosmos DB account."
}

output "azure_cosmosdb_database_id" {
  value       = azurerm_cosmosdb_sql_database.cosmosdb.id
  description = "The Cosmos DB database ID."
}

output "azure_cosmosdb_database_name" {
  value       = azurerm_cosmosdb_sql_database.cosmosdb.name
  description = "The Cosmos DB database name."
}

output "azure_cosmosdb_uri" {
  value       = azurerm_cosmosdb_account.cosmosdb.endpoint
  description = "The Cosmos DB connection string."
}

output "cosmos_app_role_definition_id" {
  value       = azurerm_cosmosdb_sql_role_definition.app_access.id
  description = "The Cosmos DB primary key."
}
