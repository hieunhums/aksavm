# =====================================================
# Foundation Module: Network Infrastructure
# =====================================================
# This module creates core network infrastructure for AKS:
# - Virtual Network
# - Subnets
# - Private DNS Zones
# - Managed Identities
# - Role Assignments
#
# State: REMOTE (uses bootstrap storage)
# =====================================================

provider "azurerm" {
  subscription_id = "1ba93e37-9d55-40ca-b240-0435b633fc72"

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

resource "azurerm_resource_group" "network" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# =====================================================
# Virtual Network with Subnets (AVM Module)
# =====================================================

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.8"

  # Basic Configuration
  name          = var.vnet_name
  parent_id     = azurerm_resource_group.network.id
  location      = azurerm_resource_group.network.location
  address_space = var.vnet_address_space

  # Subnets
  subnets = merge(
    {
      # AKS System Nodes Subnet
      aks_system = {
        name             = var.subnet_aks_system_name
        address_prefixes = var.subnet_aks_system_prefixes
      }
      # Private Endpoints Subnet
      private_endpoints = {
        name             = var.subnet_private_endpoints_name
        address_prefixes = var.subnet_private_endpoints_prefixes
      }
    },
    # Conditional AKS User Subnet
    var.create_separate_user_subnet ? {
      aks_user = {
        name             = var.subnet_aks_user_name
        address_prefixes = var.subnet_aks_user_prefixes
      }
    } : {}
  )

  # Tags
  tags = var.tags
}

# =====================================================
# Private DNS Zones
# =====================================================

# Private DNS Zone for AKS
resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}

# Link AKS DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "${var.vnet_name}-aks-link"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = module.virtual_network.resource_id
  registration_enabled  = false
  tags                  = var.tags
}

# Private DNS Zone for ACR
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}

# Link ACR DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "${var.vnet_name}-acr-link"
  resource_group_name   = azurerm_resource_group.network.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = module.virtual_network.resource_id
  registration_enabled  = false
  tags                  = var.tags
}

# =====================================================
# Managed Identity for AKS
# =====================================================

resource "azurerm_user_assigned_identity" "aks" {
  name                = var.identity_name
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  tags                = var.tags
}

# Role Assignment: Private DNS Zone Contributor for AKS
resource "azurerm_role_assignment" "aks_dns_contributor" {
  scope                = azurerm_private_dns_zone.aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# =====================================================
# Network Security Groups (Optional)
# =====================================================

resource "azurerm_network_security_group" "aks" {
  count               = var.create_nsg ? 1 : 0
  name                = "${var.vnet_name}-aks-nsg"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  # Allow AKS required outbound
  security_rule {
    name                       = "AllowAKSOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSG with AKS System Subnet
resource "azurerm_subnet_network_security_group_association" "aks_system" {
  count                     = var.create_nsg ? 1 : 0
  subnet_id                 = module.virtual_network.subnets["aks_system"].resource_id
  network_security_group_id = azurerm_network_security_group.aks[0].id
}
