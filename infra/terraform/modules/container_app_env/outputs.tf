output "id" {
  description = "ID del recurso de Azure Container App Environment."
  value       = azurerm_container_app_environment.this.id
}

output "aca_env_id" {
  description = "Alias del ID de Azure Container App Environment."
  value       = azurerm_container_app_environment.this.id
}

output "name" {
  description = "Nombre del Azure Container App Environment."
  value       = azurerm_container_app_environment.this.name
}

output "aca_env_name" {
  description = "Alias del nombre del Azure Container App Environment."
  value       = azurerm_container_app_environment.this.name
}

output "default_domain" {
  description = "Dominio DNS por defecto del entorno para resolución de Container Apps."
  value       = azurerm_container_app_environment.this.default_domain
}

output "static_ip_address" {
  description = "Dirección IP estática del Container App Environment."
  value       = azurerm_container_app_environment.this.static_ip_address
}
