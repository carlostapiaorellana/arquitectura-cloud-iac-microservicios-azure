output "id" {
  description = "ID del recurso de la cuenta de Azure Cosmos DB."
  value       = azurerm_cosmosdb_account.this.id
}

output "account_id" {
  description = "Alias del ID del recurso de la cuenta de Azure Cosmos DB."
  value       = azurerm_cosmosdb_account.this.id
}

output "cosmos_account_id" {
  description = "Alias del ID de la cuenta de Cosmos DB."
  value       = azurerm_cosmosdb_account.this.id
}

output "name" {
  description = "Nombre de la cuenta de Azure Cosmos DB."
  value       = azurerm_cosmosdb_account.this.name
}

output "endpoint" {
  description = "Endpoint HTTPS de la cuenta de Azure Cosmos DB."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "cosmos_endpoint" {
  description = "Alias del endpoint HTTPS de la cuenta de Azure Cosmos DB."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "primary_key" {
  description = "Clave primaria sensible para autenticación de Cosmos DB."
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}

output "cosmos_primary_key" {
  description = "Alias de la clave primaria sensible de Cosmos DB."
  value       = azurerm_cosmosdb_account.this.primary_key
  sensitive   = true
}

output "database_id" {
  description = "ID de la base de datos SQL en Cosmos DB."
  value       = azurerm_cosmosdb_sql_database.this.id
}

output "database_name" {
  description = "Nombre de la base de datos SQL en Cosmos DB."
  value       = azurerm_cosmosdb_sql_database.this.name
}

output "cosmos_database_name" {
  description = "Alias del nombre de la base de datos SQL en Cosmos DB."
  value       = azurerm_cosmosdb_sql_database.this.name
}

output "container_ids" {
  description = "Mapa de IDs de los contenedores NoSQL aprovisionados."
  value       = { for k, v in azurerm_cosmosdb_sql_container.this : k => v.id }
}
