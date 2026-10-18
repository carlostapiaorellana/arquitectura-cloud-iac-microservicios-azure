resource "azurerm_log_analytics_workspace" "this" {
  name                = coalesce(var.workspace_name, var.name)
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.workspace_name != null || var.name != null
      error_message = "Debe especificar 'workspace_name' o 'name' para el Log Analytics Workspace."
    }
  }
}
