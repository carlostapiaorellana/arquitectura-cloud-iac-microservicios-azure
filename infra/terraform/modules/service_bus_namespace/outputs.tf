output "id" {
  description = "ID del recurso de Azure Service Bus Namespace."
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_id" {
  description = "Alias del ID del Service Bus Namespace."
  value       = azurerm_servicebus_namespace.this.id
}

output "name" {
  description = "Nombre del Service Bus Namespace."
  value       = azurerm_servicebus_namespace.this.name
}

output "namespace_name" {
  description = "Alias del nombre del Service Bus Namespace."
  value       = azurerm_servicebus_namespace.this.name
}

output "endpoint" {
  description = "URL del endpoint de conexión del Service Bus Namespace."
  value       = azurerm_servicebus_namespace.this.endpoint
}

output "fqdn" {
  description = "FQDN del Service Bus Namespace para configuración en microservicios Go (SERVICEBUS_FQDN)."
  value       = "${azurerm_servicebus_namespace.this.name}.servicebus.windows.net"
}

output "default_primary_connection_string" {
  description = "Cadena de conexión primaria por defecto sensible (habilitada solo si local_auth_enabled = true)."
  value       = azurerm_servicebus_namespace.this.default_primary_connection_string
  sensitive   = true
}

output "default_secondary_connection_string" {
  description = "Cadena de conexión secundaria por defecto sensible."
  value       = azurerm_servicebus_namespace.this.default_secondary_connection_string
  sensitive   = true
}

output "default_primary_key" {
  description = "Clave primaria por defecto sensible del Service Bus Namespace."
  value       = azurerm_servicebus_namespace.this.default_primary_key
  sensitive   = true
}
