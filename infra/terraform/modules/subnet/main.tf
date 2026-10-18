locals {
  effective_delegations = var.delegation != null ? concat([var.delegation], var.delegations) : var.delegations
}

resource "azurerm_subnet" "this" {
  name                              = coalesce(var.subnet_name, var.name)
  resource_group_name               = var.resource_group_name
  virtual_network_name              = var.virtual_network_name
  address_prefixes                  = var.address_prefixes
  service_endpoints                 = length(var.service_endpoints) > 0 ? var.service_endpoints : null
  private_endpoint_network_policies = var.private_endpoint_network_policies
  default_outbound_access_enabled   = var.default_outbound_access_enabled

  dynamic "delegation" {
    for_each = local.effective_delegations
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.subnet_name != null || var.name != null
      error_message = "Debe especificar 'subnet_name' o 'name' para la subred."
    }
  }
}
