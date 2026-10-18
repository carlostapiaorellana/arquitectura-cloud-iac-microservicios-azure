output "id" {
  description = "ID del recurso del backend en Azure API Management."
  value       = azurerm_api_management_backend.this.id
}

output "backend_id" {
  description = "Alias del ID de recurso del backend en Azure API Management."
  value       = azurerm_api_management_backend.this.id
}

output "name" {
  description = "Nombre del backend en Azure API Management."
  value       = azurerm_api_management_backend.this.name
}

output "backend_name" {
  description = "Alias del nombre del backend en Azure API Management."
  value       = azurerm_api_management_backend.this.name
}

output "url" {
  description = "URL del endpoint de backend configurada en APIM."
  value       = azurerm_api_management_backend.this.url
}
