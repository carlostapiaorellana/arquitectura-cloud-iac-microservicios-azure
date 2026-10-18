output "id" {
  description = "ID del recurso de la regla de autorización de Service Bus."
  value       = try(azurerm_servicebus_namespace_authorization_rule.this[0].id, null)
}

output "auth_rule_id" {
  description = "Alias del ID de recurso de la regla de autorización de Service Bus."
  value       = try(azurerm_servicebus_namespace_authorization_rule.this[0].id, null)
}

output "name" {
  description = "Nombre de la regla de autorización de Service Bus."
  value       = try(azurerm_servicebus_namespace_authorization_rule.this[0].name, null)
}

output "primary_connection_string" {
  description = "Cadena de conexión primaria sensible generada por la regla de autorización."
  value       = try(azurerm_servicebus_namespace_authorization_rule.this[0].primary_connection_string, null)
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Cadena de conexión secundaria sensible generada por la regla de autorización."
  value       = try(azurerm_servicebus_namespace_authorization_rule.this[0].secondary_connection_string, null)
  sensitive   = true
}

output "primary_key" {
  description = "Clave primaria sensible generada por la regla de autorización."
  value       = try(azurerm_servicebus_namespace_authorization_rule.this[0].primary_key, null)
  sensitive   = true
}

output "secondary_key" {
  description = "Clave secundaria sensible generada por la regla de autorización."
  value       = try(azurerm_servicebus_namespace_authorization_rule.this[0].secondary_key, null)
  sensitive   = true
}
