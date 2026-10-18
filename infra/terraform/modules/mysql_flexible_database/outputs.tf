output "id" {
  description = "ID del recurso de la base de datos MySQL Flexible."
  value       = azurerm_mysql_flexible_database.this.id
}

output "database_id" {
  description = "Alias del ID de la base de datos MySQL Flexible."
  value       = azurerm_mysql_flexible_database.this.id
}

output "name" {
  description = "Nombre de la base de datos MySQL Flexible."
  value       = azurerm_mysql_flexible_database.this.name
}

output "database_name" {
  description = "Alias del nombre de la base de datos MySQL Flexible."
  value       = azurerm_mysql_flexible_database.this.name
}

output "server_name" {
  description = "Nombre del servidor MySQL asociado."
  value       = azurerm_mysql_flexible_database.this.server_name
}
