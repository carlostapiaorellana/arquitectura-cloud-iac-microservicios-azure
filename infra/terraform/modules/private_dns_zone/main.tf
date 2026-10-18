resource "azurerm_private_dns_zone" "this" {
  name                = coalesce(var.dns_zone_name, var.name)
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = var.dns_zone_name != null || var.name != null
      error_message = "Debe especificar 'dns_zone_name' o 'name' para la Zona DNS Privada."
    }
  }
}
