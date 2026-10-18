output "id" {
  description = "ID del recurso de Service Bus Topic."
  value       = azurerm_servicebus_topic.this.id
}

output "topic_id" {
  description = "Alias del ID de recurso de Service Bus Topic."
  value       = azurerm_servicebus_topic.this.id
}

output "name" {
  description = "Nombre del Service Bus Topic."
  value       = azurerm_servicebus_topic.this.name
}

output "topic_name" {
  description = "Alias del nombre del Service Bus Topic."
  value       = azurerm_servicebus_topic.this.name
}
