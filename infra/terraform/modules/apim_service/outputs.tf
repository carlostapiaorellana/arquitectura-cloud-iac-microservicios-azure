output "id" {
  value       = azurerm_api_management.this.id
  description = "ID del servicio de Azure API Management."
}

output "name" {
  value       = azurerm_api_management.this.name
  description = "Nombre de la instancia de Azure API Management."
}

output "gateway_url" {
  value       = azurerm_api_management.this.gateway_url
  description = "URL del API Gateway perimetral."
}

output "management_api_url" {
  value       = azurerm_api_management.this.management_api_url
  description = "URL de la API de gestión de Azure API Management."
}

output "portal_url" {
  value       = azurerm_api_management.this.portal_url
  description = "URL del portal heredado de desarrollador."
}

output "developer_portal_url" {
  value       = azurerm_api_management.this.developer_portal_url
  description = "URL del nuevo portal de desarrolladores de Azure API Management."
}

output "identity_principal_id" {
  value       = try(azurerm_api_management.this.identity[0].principal_id, null)
  description = "Principal ID de la Managed Identity asignada por el sistema."
}

output "identity_tenant_id" {
  value       = try(azurerm_api_management.this.identity[0].tenant_id, null)
  description = "Tenant ID de la Managed Identity del servicio APIM."
}
