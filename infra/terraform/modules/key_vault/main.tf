resource "azurerm_key_vault" "this" {
  name                          = coalesce(var.key_vault_name, var.name)
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = lower(var.sku_name)
  rbac_authorization_enabled    = coalesce(var.rbac_authorization_enabled, var.enable_rbac_authorization)
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    default_action             = var.network_acls.default_action
    bypass                     = var.network_acls.bypass
    ip_rules                   = length(var.network_acls.ip_rules) > 0 ? var.network_acls.ip_rules : var.ip_rules
    virtual_network_subnet_ids = length(var.network_acls.virtual_network_subnet_ids) > 0 ? var.network_acls.virtual_network_subnet_ids : var.virtual_network_subnet_ids
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.key_vault_name != null || var.name != null
      error_message = "Debe especificar 'key_vault_name' o 'name' (entre 3 y 24 caracteres) para el Key Vault."
    }
  }
}
