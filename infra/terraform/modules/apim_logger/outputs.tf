output "id" {
  description = "ID del recurso de logger en Azure API Management."
  value       = azurerm_api_management_logger.this.id
}

output "logger_id" {
  description = "Alias del ID de recurso de logger en Azure API Management."
  value       = azurerm_api_management_logger.this.id
}

output "name" {
  description = "Nombre del logger en Azure API Management."
  value       = azurerm_api_management_logger.this.name
}

output "logger_name" {
  description = "Alias del nombre del logger en Azure API Management."
  value       = azurerm_api_management_logger.this.name
}
