# =====================================================
# Foundation Module Outputs
# =====================================================
# These outputs are consumed by the AKS module via
# Terraform remote state data source
# =====================================================

# Resource Group
output "resource_group_name" {
  description = "Name of the network resource group"
  value       = azurerm_resource_group.network.name
}

output "resource_group_id" {
  description = "ID of the network resource group"
  value       = azurerm_resource_group.network.id
}

# Virtual Network
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.virtual_network.resource_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.virtual_network.name
}

# Subnets
output "subnet_aks_system_id" {
  description = "ID of the AKS system nodes subnet"
  value       = module.virtual_network.subnets["aks_system"].resource_id
}

output "subnet_aks_user_id" {
  description = "ID of the AKS user nodes subnet (same as system if not created separately)"
  value       = var.create_separate_user_subnet ? module.virtual_network.subnets["aks_user"].resource_id : module.virtual_network.subnets["aks_system"].resource_id
}

output "subnet_private_endpoints_id" {
  description = "ID of the private endpoints subnet"
  value       = module.virtual_network.subnets["private_endpoints"].resource_id
}

# Private DNS Zones
output "private_dns_zone_aks_id" {
  description = "ID of the AKS private DNS zone"
  value       = azurerm_private_dns_zone.aks.id
}

output "private_dns_zone_aks_name" {
  description = "Name of the AKS private DNS zone"
  value       = azurerm_private_dns_zone.aks.name
}

output "private_dns_zone_acr_id" {
  description = "ID of the ACR private DNS zone"
  value       = azurerm_private_dns_zone.acr.id
}

output "private_dns_zone_acr_name" {
  description = "Name of the ACR private DNS zone"
  value       = azurerm_private_dns_zone.acr.name
}

# Managed Identity
output "aks_identity_id" {
  description = "ID of the user-assigned managed identity for AKS"
  value       = azurerm_user_assigned_identity.aks.id
}

output "aks_identity_principal_id" {
  description = "Principal ID of the AKS managed identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "aks_identity_client_id" {
  description = "Client ID of the AKS managed identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

# Network Configuration for AKS Module
output "network_config" {
  description = "Complete network configuration for AKS module consumption via remote state"
  value = {
    vnet_id                     = module.virtual_network.resource_id
    vnet_name                   = module.virtual_network.name
    subnet_aks_system_id        = module.virtual_network.subnets["aks_system"].resource_id
    subnet_aks_user_id          = var.create_separate_user_subnet ? module.virtual_network.subnets["aks_user"].resource_id : module.virtual_network.subnets["aks_system"].resource_id
    subnet_private_endpoints_id = module.virtual_network.subnets["private_endpoints"].resource_id
    private_dns_zone_aks_id     = azurerm_private_dns_zone.aks.id
    private_dns_zone_acr_id     = azurerm_private_dns_zone.acr.id
    identity_id                 = azurerm_user_assigned_identity.aks.id
    identity_principal_id       = azurerm_user_assigned_identity.aks.principal_id
    identity_client_id          = azurerm_user_assigned_identity.aks.client_id
  }
}
