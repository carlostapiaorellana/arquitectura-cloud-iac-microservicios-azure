output "id" {
  description = "ID del recurso de la configuración de diagnóstico."
  value       = azurerm_monitor_diagnostic_setting.this.id
}

output "diagnostic_setting_id" {
  description = "Alias del ID de la configuración de diagnóstico."
  value       = azurerm_monitor_diagnostic_setting.this.id
}

output "name" {
  description = "Nombre de la configuración de diagnóstico."
  value       = azurerm_monitor_diagnostic_setting.this.name
}

output "target_resource_id" {
  description = "ID del recurso de Azure monitoreado."
  value       = azurerm_monitor_diagnostic_setting.this.target_resource_id
}
