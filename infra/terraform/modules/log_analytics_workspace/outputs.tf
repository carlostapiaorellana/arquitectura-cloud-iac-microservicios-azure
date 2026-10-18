output "id" {
  description = "ID del recurso de Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_id" {
  description = "Alias del ID de recurso de Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "name" {
  description = "Nombre del Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_name" {
  description = "Alias del nombre del Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "workspace_customer_id" {
  description = "Identificador único GUID del espacio de trabajo (Customer ID) para agentes y diagnóstico."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "primary_shared_key" {
  description = "Clave compartida primaria sensible para la ingesta de telemetría y logs."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "Clave compartida secundaria sensible para la rotación de credenciales."
  value       = azurerm_log_analytics_workspace.this.secondary_shared_key
  sensitive   = true
}
