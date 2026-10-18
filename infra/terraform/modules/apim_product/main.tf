resource "azurerm_api_management_product" "this" {
  product_id            = coalesce(var.product_id, var.name)
  api_management_name   = var.api_management_name
  resource_group_name   = var.resource_group_name
  display_name          = var.display_name
  description           = var.description
  subscription_required = var.subscription_required
  approval_required     = var.approval_required
  published             = var.published
  subscriptions_limit   = var.subscriptions_limit
  terms                 = var.terms

  lifecycle {
    precondition {
      condition     = var.product_id != null || var.name != null
      error_message = "Debe especificar 'product_id' o 'name' para el producto de Azure API Management."
    }
  }
}

resource "azurerm_api_management_product_api" "this" {
  for_each            = toset(var.api_names)
  api_name            = each.value
  product_id          = azurerm_api_management_product.this.product_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
}
