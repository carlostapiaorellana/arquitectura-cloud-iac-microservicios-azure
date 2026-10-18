output "id" {
  description = "ID de recurso en Azure de la User-Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "identity_id" {
  description = "Alias del ID de recurso en Azure de la User-Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "name" {
  description = "Nombre de la User-Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.this.name
}

output "principal_id" {
  description = "Object ID (Principal ID) del Service Principal asociado en Microsoft Entra ID."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Application / Client ID de la identidad administrada para configurar AZURE_CLIENT_ID en los microservicios."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "tenant_id" {
  description = "UUID del Tenant de Microsoft Entra ID al que pertenece la identidad."
  value       = azurerm_user_assigned_identity.this.tenant_id
}
