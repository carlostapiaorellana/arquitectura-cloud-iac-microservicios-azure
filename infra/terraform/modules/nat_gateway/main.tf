locals {
  effective_name = coalesce(var.nat_gateway_name, var.name)
  effective_pip  = coalesce(var.public_ip_name, "pip-${local.effective_name}")
}

resource "azurerm_public_ip" "this" {
  name                = local.effective_pip
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = var.sku_name
  zones               = length(var.zones) > 0 ? var.zones : null
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                    = local.effective_name
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = var.sku_name
  idle_timeout_in_minutes = var.idle_timeout_in_minutes
  zones                   = length(var.zones) > 0 ? var.zones : null
  tags                    = var.tags

  lifecycle {
    precondition {
      condition     = var.nat_gateway_name != null || var.name != null
      error_message = "Debe especificar 'nat_gateway_name' o 'name' para el NAT Gateway."
    }
  }
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.this.id
}

resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each = var.subnet_ids

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.this.id
}
