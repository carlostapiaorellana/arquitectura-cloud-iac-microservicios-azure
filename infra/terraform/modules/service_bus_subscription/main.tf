resource "azurerm_servicebus_subscription" "this" {
  name                                      = coalesce(var.subscription_name, var.name)
  topic_id                                  = var.topic_id
  max_delivery_count                        = var.max_delivery_count
  lock_duration                             = var.lock_duration
  dead_lettering_on_message_expiration      = var.dead_lettering_on_message_expiration
  dead_lettering_on_filter_evaluation_error = var.dead_lettering_on_filter_evaluation_error
  default_message_ttl                       = var.default_message_ttl
  auto_delete_on_idle                       = var.auto_delete_on_idle
  status                                    = var.status

  lifecycle {
    precondition {
      condition     = var.subscription_name != null || var.name != null
      error_message = "Debe especificar 'subscription_name' o 'name' para la suscripción de Service Bus."
    }
  }
}
