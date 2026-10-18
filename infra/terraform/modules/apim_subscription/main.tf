resource "azurerm_api_management_subscription" "this" {
  subscription_id     = var.subscription_id
  api_management_name = var.api_management_name
  resource_group_name = var.resource_group_name
  display_name        = var.display_name
  product_id          = var.product_id
  api_id              = var.api_id
  user_id             = var.user_id
  state               = var.state
  allow_tracing       = var.allow_tracing
  primary_key         = var.primary_key
  secondary_key       = var.secondary_key

  lifecycle {
    precondition {
      condition     = var.product_id != null || var.api_id != null
      error_message = "Debe asociar la suscripción a un 'product_id' o a un 'api_id'."
    }
  }
}
