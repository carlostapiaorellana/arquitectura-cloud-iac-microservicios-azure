output "id" {
  description = "ID del servidor MySQL Flexible Server."
  value       = azurerm_mysql_flexible_server.this.id
}

output "server_id" {
  description = "Alias del ID del servidor MySQL Flexible Server."
  value       = azurerm_mysql_flexible_server.this.id
}

output "name" {
  description = "Nombre del servidor MySQL Flexible Server."
  value       = azurerm_mysql_flexible_server.this.name
}

output "server_name" {
  description = "Alias del nombre del servidor MySQL Flexible Server."
  value       = azurerm_mysql_flexible_server.this.name
}

output "fqdn" {
  description = "FQDN del servidor MySQL Flexible Server para conexión de aplicaciones."
  value       = azurerm_mysql_flexible_server.this.fqdn
}

output "administrator_login" {
  description = "Nombre de usuario administrador del servidor MySQL."
  value       = azurerm_mysql_flexible_server.this.administrator_login
}

output "public_network_access_enabled" {
  description = "Estado de acceso público del servidor MySQL Flexible Server."
  value       = azurerm_mysql_flexible_server.this.public_network_access_enabled
}
