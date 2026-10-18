resource "azurerm_container_app_environment" "this" {
  name                           = coalesce(var.environment_name, var.name)
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  zone_redundancy_enabled        = var.zone_redundancy_enabled

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.environment_name != null || var.name != null
      error_message = "Debe especificar 'environment_name' o 'name' para el Container App Environment."
    }
  }
}
