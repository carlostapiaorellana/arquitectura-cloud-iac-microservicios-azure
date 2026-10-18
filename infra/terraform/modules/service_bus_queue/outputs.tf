output "id" {
  description = "ID del recurso de Service Bus Queue."
  value       = azurerm_servicebus_queue.this.id
}

output "queue_id" {
  description = "Alias del ID de recurso de Service Bus Queue."
  value       = azurerm_servicebus_queue.this.id
}

output "name" {
  description = "Nombre de la cola de Service Bus."
  value       = azurerm_servicebus_queue.this.name
}

output "queue_name" {
  description = "Alias del nombre de la cola de Service Bus."
  value       = azurerm_servicebus_queue.this.name
}
