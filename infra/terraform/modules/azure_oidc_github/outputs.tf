output "client_id" {
  description = "Application (Client) ID de la aplicación en Microsoft Entra ID."
  value       = azuread_application.this.client_id
}

output "tenant_id" {
  description = "Directory (Tenant) ID de Microsoft Entra ID."
  value       = try(data.azuread_client_config.current.tenant_id, var.tenant_id)
}

output "service_principal_object_id" {
  description = "Object ID del Service Principal en Microsoft Entra ID."
  value       = azuread_service_principal.this.object_id
}

output "application_id" {
  description = "Resource ID de la aplicación en Microsoft Entra ID."
  value       = azuread_application.this.id
}
