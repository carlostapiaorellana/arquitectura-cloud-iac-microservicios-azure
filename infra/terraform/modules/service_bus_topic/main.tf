resource "azurerm_servicebus_topic" "this" {
  name                                    = coalesce(var.topic_name, var.name)
  namespace_id                            = var.namespace_id
  support_ordering                        = var.support_ordering
  requires_duplicate_detection            = var.requires_duplicate_detection
  duplicate_detection_history_time_window = var.requires_duplicate_detection ? var.duplicate_detection_history_time_window : null
  max_size_in_megabytes                   = var.max_size_in_megabytes
  default_message_ttl                     = var.default_message_ttl
  auto_delete_on_idle                     = var.auto_delete_on_idle
  status                                  = var.status

  lifecycle {
    precondition {
      condition     = var.topic_name != null || var.name != null
      error_message = "Debe especificar 'topic_name' o 'name' para el Service Bus Topic."
    }
  }
}
