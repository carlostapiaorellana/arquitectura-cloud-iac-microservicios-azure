terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0, < 5.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.50.0, < 4.0.0"
    }
  }
}
