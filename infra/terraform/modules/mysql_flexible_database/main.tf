resource "azurerm_mysql_flexible_database" "this" {
  name                = coalesce(var.database_name, var.name)
  resource_group_name = var.resource_group_name
  server_name         = var.server_name
  charset             = var.charset
  collation           = var.collation

  lifecycle {
    precondition {
      condition     = var.database_name != null || var.name != null
      error_message = "Debe especificar 'database_name' o 'name' para la base de datos MySQL."
    }
  }
}
