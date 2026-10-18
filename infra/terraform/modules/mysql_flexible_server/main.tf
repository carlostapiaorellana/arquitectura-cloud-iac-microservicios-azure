resource "azurerm_mysql_flexible_server" "this" {
  name                   = coalesce(var.server_name, var.name)
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password
  sku_name               = var.sku_name
  version                = var.mysql_version
  zone                   = var.zone

  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  storage {
    size_gb            = var.storage_gb
    auto_grow_enabled  = var.auto_grow_enabled
    io_scaling_enabled = var.io_scaling_enabled
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.server_name != null || var.name != null
      error_message = "Debe especificar 'server_name' o 'name' para el servidor MySQL Flexible Server."
    }
  }
}
