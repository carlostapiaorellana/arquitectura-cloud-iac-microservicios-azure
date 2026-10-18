terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.50"
    }
  }
}

provider "azurerm" {
  resource_provider_registrations = "none"
  features {}
  storage_use_azuread = false # Evita error 403 AuthorizationFailure en hosts locales (patron-azure-storage-dev / INC-001)
}

provider "azuread" {}
