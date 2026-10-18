locals {
  merged_configurations = merge(
    var.configurations,
    var.configuration_name != null && var.value != null ? { (var.configuration_name) = var.value } : {}
  )
}

resource "azurerm_mysql_flexible_server_configuration" "this" {
  for_each            = local.merged_configurations
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = var.server_name
  value               = each.value
}
