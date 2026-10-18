output "id" {
  value       = azurerm_api_management_api.this.id
  description = "ID de la API en Azure API Management."
}

output "name" {
  value       = azurerm_api_management_api.this.name
  description = "Nombre identificador de la API."
}

output "path" {
  value       = azurerm_api_management_api.this.path
  description = "Ruta perimetral de la API."
}

output "service_url" {
  value       = azurerm_api_management_api.this.service_url
  description = "URL del servicio backend configurada en la API."
}

output "is_current" {
  value       = azurerm_api_management_api.this.is_current
  description = "Indica si la revisión actual es la activa."
}
