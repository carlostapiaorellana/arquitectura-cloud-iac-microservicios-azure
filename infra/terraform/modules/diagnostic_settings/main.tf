resource "azurerm_monitor_diagnostic_setting" "this" {
  name                           = var.name
  target_resource_id             = var.target_resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = var.log_analytics_destination_type
  storage_account_id             = var.storage_account_id
  eventhub_name                  = var.eventhub_name
  eventhub_authorization_rule_id = var.eventhub_authorization_rule_id

  dynamic "enabled_log" {
    for_each = var.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = var.log_category_groups
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }

  lifecycle {
    precondition {
      condition     = var.log_analytics_workspace_id != null || var.storage_account_id != null || var.eventhub_authorization_rule_id != null
      error_message = "Debe especificarse al menos un destino para el diagnóstico (log_analytics_workspace_id, storage_account_id o eventhub_authorization_rule_id)."
    }
  }
}
