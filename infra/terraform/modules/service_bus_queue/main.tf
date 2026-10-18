resource "azurerm_servicebus_queue" "this" {
  name                                    = coalesce(var.queue_name, var.name)
  namespace_id                            = var.namespace_id
  lock_duration                           = var.lock_duration
  max_delivery_count                      = var.max_delivery_count
  max_size_in_megabytes                   = var.max_size_in_megabytes
  requires_duplicate_detection            = var.requires_duplicate_detection
  duplicate_detection_history_time_window = var.requires_duplicate_detection ? var.duplicate_detection_history_time_window : null
  dead_lettering_on_message_expiration    = var.dead_lettering_on_message_expiration
  default_message_ttl                     = var.default_message_ttl
  auto_delete_on_idle                     = var.auto_delete_on_idle
  status                                  = var.status

  lifecycle {
    precondition {
      condition     = var.queue_name != null || var.name != null
      error_message = "Debe especificar 'queue_name' o 'name' para la cola de Service Bus."
    }
  }
}
