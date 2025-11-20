# =====================================================
# Subscription Vending with Azure Verified Modules
# =====================================================
# This module creates and configures new Azure subscriptions
# with standardized governance, networking, and RBAC.
#
# Use cases:
# - Landing zone deployment
# - New project/team subscription provisioning
# - Standardized subscription configuration
# =====================================================

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azuread" {}

# =====================================================
# Data Sources
# =====================================================

data "azurerm_client_config" "current" {}

# =====================================================
# Subscription Vending (AVM Pattern Module)
# =====================================================

module "subscription_vending" {
  source  = "Azure/lz-vending/azurerm"
  version = "~> 4.0"

  # =====================================================
  # Subscription Configuration
  # =====================================================

  # Create new subscription via alias
  subscription_alias_enabled = var.subscription_alias_enabled
  subscription_billing_scope = var.subscription_billing_scope
  subscription_display_name  = var.subscription_display_name
  subscription_alias_name    = var.subscription_alias_name
  subscription_workload      = var.subscription_workload
  subscription_tags          = var.subscription_tags

  # Or use existing subscription
  subscription_id = var.subscription_id

  # Management Group Association
  subscription_management_group_association_enabled = var.subscription_management_group_association_enabled
  subscription_management_group_id                  = var.subscription_management_group_id

  # =====================================================
  # Virtual Network Configuration
  # =====================================================

  virtual_network_enabled = var.virtual_network_enabled
  virtual_networks        = var.virtual_networks

  # =====================================================
  # Role Assignments
  # =====================================================

  role_assignment_enabled = var.role_assignment_enabled
  role_assignments        = var.role_assignments

  # =====================================================
  # Resource Groups
  # =====================================================

  resource_group_creation_enabled = var.resource_group_creation_enabled
  resource_groups                 = var.resource_groups

  # =====================================================
  # Budget Configuration
  # =====================================================

  budget_enabled = var.budget_enabled
  budgets        = var.budgets

  # =====================================================
  # Telemetry
  # =====================================================

  enable_telemetry = var.enable_telemetry
}
