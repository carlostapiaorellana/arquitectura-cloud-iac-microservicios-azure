resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = coalesce(var.link_name, var.name)
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = var.private_dns_zone_name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = var.registration_enabled
  tags                  = var.tags

  lifecycle {
    precondition {
      condition     = var.link_name != null || var.name != null
      error_message = "Debe especificar 'link_name' o 'name' para el enlace de Zona DNS Privada."
    }
  }
}
