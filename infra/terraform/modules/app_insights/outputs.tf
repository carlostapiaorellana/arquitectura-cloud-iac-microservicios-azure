output "id" {
  description = "ID del recurso de Azure Application Insights."
  value       = azurerm_application_insights.this.id
}

output "app_insights_id" {
  description = "Alias del ID de recurso de Azure Application Insights."
  value       = azurerm_application_insights.this.id
}

output "name" {
  description = "Nombre del recurso Application Insights."
  value       = azurerm_application_insights.this.name
}

output "app_id" {
  description = "App ID de Application Insights."
  value       = azurerm_application_insights.this.app_id
}

output "instrumentation_key" {
  description = "Instrumentation Key sensible para SDKs de telemetría."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "Cadena de conexión sensible para SDKs modernos de telemetría (OpenTelemetry / Azure Monitor SDK)."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}
