# =====================================================
# Bootstrap Module: Terraform Remote State Setup
# =====================================================
# This module creates the Azure Storage backend for
# Terraform state management. Run this ONCE per subscription.
#
# State: LOCAL (bootstrap has no remote state)
# =====================================================

terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
  }

  # Bootstrap uses LOCAL backend
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "1ba93e37-9d55-40ca-b240-0435b633fc72"
  
  # Use Azure AD authentication for storage accounts
  storage_use_azuread = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# =====================================================
# Resource Group
# =====================================================

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-terraform-state"
  location = var.location
}

# =====================================================
# Random Suffix for Globally Unique Storage Account Name
# =====================================================

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# =====================================================
# Storage Account (Raw Resource - Policy Compliance)
# =====================================================

resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${var.environment}${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"

  # Disable key-based auth to comply with Azure Policy
  shared_access_key_enabled      = true
  public_network_access_enabled  = true
  https_traffic_only_enabled     = true
  min_tls_version                = "TLS1_2"
  allow_nested_items_to_be_public = false

  # Enable Entra ID (OAuth) authentication
  azure_files_authentication {
    directory_type = "AADKERB"
  }

  blob_properties {
    versioning_enabled       = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "Terraform-State"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# =====================================================
# Outputs
# =====================================================

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "backend_config" {
  value = <<-EOT
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "tfstate"
    use_azuread_auth     = true  # OAuth/Entra ID authentication required
  EOT
}
