resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

resource "azurerm_storage_account" "this" {
  name                            = coalesce(var.storage_account_name, "sttfstate${random_string.suffix.result}")
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  # Reglas obligatorias para despliegue local (INC-001 / AZ-01 / patron-azure-storage-dev):
  public_network_access_enabled = true
  shared_access_key_enabled     = true
  https_traffic_only_enabled    = true

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id # Mandatorio en azurerm v4 (INC-001 / patron-azure-storage-dev)
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Módulo de Federación OIDC para GitHub Actions (Microsoft Entra ID)
# -----------------------------------------------------------------------------
module "azure_oidc_github" {
  source                 = "../modules/azure_oidc_github"
  github_repository      = var.github_repository
  service_principal_name = var.service_principal_name
  subscription_id        = var.subscription_id
}
