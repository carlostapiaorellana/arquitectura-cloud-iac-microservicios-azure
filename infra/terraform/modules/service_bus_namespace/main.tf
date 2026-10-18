resource "azurerm_servicebus_namespace" "this" {
  name                          = coalesce(var.namespace_name, var.name)
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  capacity                      = var.sku == "Premium" ? var.capacity : null
  local_auth_enabled            = var.local_auth_enabled
  minimum_tls_version           = var.minimum_tls_version
  public_network_access_enabled = var.public_network_access_enabled

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.namespace_name != null || var.name != null
      error_message = "Debe especificar 'namespace_name' o 'name' para el Service Bus Namespace."
    }
  }
}
