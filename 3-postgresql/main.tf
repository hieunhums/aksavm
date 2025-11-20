# =====================================================
# PostgreSQL Flexible Server with Azure Verified Modules
# =====================================================

# Network configuration from foundation
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = var.backend_storage_account_name
    container_name       = "tfstate"
    key                  = "network.tfstate"
    use_azuread_auth     = true
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
# Data Sources
# =====================================================

data "azurerm_client_config" "current" {}

# =====================================================
# Resource Group
# =====================================================

resource "azurerm_resource_group" "postgresql" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# =====================================================
# Private DNS Zone for PostgreSQL
# =====================================================

resource "azurerm_private_dns_zone" "postgresql" {
  count               = var.delegated_subnet_id != null ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.postgresql.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  count                 = var.delegated_subnet_id != null ? 1 : 0
  name                  = "${var.name}-postgresql-link"
  resource_group_name   = azurerm_resource_group.postgresql.name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql[0].name
  virtual_network_id    = data.terraform_remote_state.network.outputs.network_config.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# =====================================================
# Random Password (if not provided)
# =====================================================

resource "random_password" "administrator" {
  count   = var.administrator_password == "" ? 1 : 0
  length  = 24
  special = true
}

# =====================================================
# PostgreSQL Flexible Server (AVM Module)
# =====================================================

module "postgresql" {
  source  = "Azure/avm-res-dbforpostgresql-flexibleserver/azurerm"
  version = "~> 0.1"

  # Basic Configuration
  name                = var.name
  resource_group_name = azurerm_resource_group.postgresql.name
  location            = azurerm_resource_group.postgresql.location

  # Server Configuration
  sku_name       = var.sku_name
  storage_mb     = var.storage_mb
  server_version = var.postgresql_version
  zone           = var.zone

  # Authentication
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password != "" ? var.administrator_password : random_password.administrator[0].result

  authentication = {
    active_directory_auth_enabled = var.authentication.active_directory_auth_enabled
    password_auth_enabled         = var.authentication.password_auth_enabled
    tenant_id                     = var.authentication.tenant_id != null ? var.authentication.tenant_id : data.azurerm_client_config.current.tenant_id
  }

  # Network Configuration
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = var.delegated_subnet_id != null ? azurerm_private_dns_zone.postgresql[0].id : var.private_dns_zone_id
  public_network_access_enabled = var.public_network_access_enabled

  # High Availability
  high_availability = var.high_availability_mode != "Disabled" ? {
    mode                      = var.high_availability_mode
    standby_availability_zone = var.standby_availability_zone
  } : null

  # Backup
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # Databases
  databases = var.databases

  # Tags & Telemetry
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}
