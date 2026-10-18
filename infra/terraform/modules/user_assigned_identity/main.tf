resource "azurerm_user_assigned_identity" "this" {
  name                = coalesce(var.identity_name, var.name)
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = var.identity_name != null || var.name != null
      error_message = "Debe especificar 'identity_name' o 'name' para la User-Assigned Managed Identity."
    }
  }
}
