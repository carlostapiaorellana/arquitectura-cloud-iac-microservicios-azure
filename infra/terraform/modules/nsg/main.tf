resource "azurerm_network_security_group" "this" {
  name                = coalesce(var.nsg_name, var.name)
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = var.nsg_name != null || var.name != null
      error_message = "Debe especificar 'nsg_name' o 'name' para el Network Security Group."
    }
  }
}
