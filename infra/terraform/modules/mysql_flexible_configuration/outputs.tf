output "configurations" {
  description = "Mapa de configuraciones aplicadas al servidor MySQL Flexible Server."
  value       = { for k, v in azurerm_mysql_flexible_server_configuration.this : k => v.value }
}

output "ids" {
  description = "Mapa de IDs de recurso de las configuraciones aplicadas."
  value       = { for k, v in azurerm_mysql_flexible_server_configuration.this : k => v.id }
}
