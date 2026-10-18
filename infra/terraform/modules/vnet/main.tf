resource "azurerm_virtual_network" "this" {
  name                = coalesce(var.vnet_name, var.name)
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = length(var.dns_servers) > 0 ? var.dns_servers : null
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = var.vnet_name != null || var.name != null
      error_message = "Debe especificar 'vnet_name' o 'name' para la red virtual."
    }
  }
}
