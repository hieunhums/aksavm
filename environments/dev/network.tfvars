# =====================================================
# Network Module Configuration
# =====================================================

# Azure Region
location = "australiaeast"

# Resource Group
resource_group_name = "rg-aks-network-dev"

# Virtual Network
vnet_name          = "vnet-aks-dev"
vnet_address_space = ["10.0.0.0/16"]

# AKS System Nodes Subnet
subnet_aks_system_name     = "snet-aks-system"
subnet_aks_system_prefixes = ["10.0.0.0/22"]

# AKS User Nodes Subnet (Optional)
create_separate_user_subnet = false
subnet_aks_user_name        = "snet-aks-user"
subnet_aks_user_prefixes    = []

# Private Endpoints Subnet
subnet_private_endpoints_name     = "snet-private-endpoints"
subnet_private_endpoints_prefixes = ["10.0.4.0/24"]

# Managed Identity
identity_name = "id-aks-dev"

# Network Security
create_nsg = true

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "AKS"
}
