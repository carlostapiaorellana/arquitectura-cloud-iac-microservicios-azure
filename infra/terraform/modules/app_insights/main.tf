resource "azurerm_application_insights" "this" {
  name                                 = coalesce(var.app_insights_name, var.name)
  location                             = var.location
  resource_group_name                  = var.resource_group_name
  workspace_id                         = var.workspace_id
  application_type                     = var.application_type
  retention_in_days                    = var.retention_in_days
  daily_data_cap_in_gb                 = var.daily_data_cap_in_gb
  daily_data_cap_notifications_enabled = var.daily_data_cap_notifications_enabled

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.app_insights_name != null || var.name != null
      error_message = "Debe especificar 'app_insights_name' o 'name' para Application Insights."
    }
  }
}
