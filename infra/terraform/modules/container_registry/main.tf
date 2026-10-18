resource "azurerm_container_registry" "this" {
  name                          = coalesce(var.registry_name, var.name)
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = var.sku == "Premium" ? var.zone_redundancy_enabled : false

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.registry_name != null || var.name != null
      error_message = "Debe especificar 'registry_name' o 'name' para el Azure Container Registry."
    }
  }
}
