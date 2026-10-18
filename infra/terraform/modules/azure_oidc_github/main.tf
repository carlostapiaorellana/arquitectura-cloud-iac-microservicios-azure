data "azuread_client_config" "current" {}

locals {
  github_owner   = split("/", var.github_repository)[0]
  github_repo    = split("/", var.github_repository)[1]
  immutable_repo = var.github_owner_id != null && var.github_repository_id != null ? "${local.github_owner}@${var.github_owner_id}/${local.github_repo}@${var.github_repository_id}" : null
}

resource "azuread_application" "this" {
  display_name = var.service_principal_name
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application.this.client_id
}

# Credenciales OIDC: Formato clásico por nombre
resource "azuread_application_federated_identity_credential" "main" {
  application_id = azuread_application.this.id
  display_name   = "gh-federated-main"
  description    = "Credencial federada OIDC para GitHub Actions en rama main (nombre)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "azure_dev" {
  application_id = azuread_application.this.id
  display_name   = "gh-federated-azure-dev"
  description    = "Credencial federada OIDC para GitHub Actions en entorno azure-dev (nombre)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:environment:azure-dev"
}

# Credenciales OIDC: Formato inmutable con IDs numéricos (protección contra renombramiento)
resource "azuread_application_federated_identity_credential" "main_immutable" {
  count          = local.immutable_repo != null ? 1 : 0
  application_id = azuread_application.this.id
  display_name   = "gh-federated-main-id"
  description    = "Credencial federada OIDC para GitHub Actions en rama main (ID inmutable)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.immutable_repo}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "azure_dev_immutable" {
  count          = local.immutable_repo != null ? 1 : 0
  application_id = azuread_application.this.id
  display_name   = "gh-federated-azure-dev-id"
  description    = "Credencial federada OIDC para GitHub Actions en entorno azure-dev (ID inmutable)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${local.immutable_repo}:environment:azure-dev"
}

resource "azurerm_role_assignment" "this" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = var.role_definition_name
  principal_id         = azuread_service_principal.this.object_id
  principal_type       = "ServicePrincipal"
}

