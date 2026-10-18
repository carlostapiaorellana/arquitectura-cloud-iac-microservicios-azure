output "id" {
  description = "ID del recurso de Service Bus Subscription."
  value       = azurerm_servicebus_subscription.this.id
}

output "subscription_id" {
  description = "Alias del ID de recurso de Service Bus Subscription."
  value       = azurerm_servicebus_subscription.this.id
}

output "name" {
  description = "Nombre de la suscripción."
  value       = azurerm_servicebus_subscription.this.name
}

output "subscription_name" {
  description = "Alias del nombre de la suscripción."
  value       = azurerm_servicebus_subscription.this.name
}
