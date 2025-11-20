# =====================================================
# Production AKS with Azure Verified Modules (AVM)
# =====================================================

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

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

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

# Production-ready AKS cluster with AVM
module "aks_cluster" {
  source  = "Azure/avm-ptn-aks-production/azurerm"
  version = "~> 0.1"

  # Core configuration
  name                = var.name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  kubernetes_version  = var.kubernetes_version

  # Network with CNI Overlay
  network = {
    node_subnet_id = data.terraform_remote_state.network.outputs.network_config.subnet_aks_system_id
    pod_cidr       = var.pod_cidr
    service_cidr   = var.service_cidr
    dns_service_ip = var.dns_service_ip
  }
  network_policy = var.network_policy

  # Node pools
  default_node_pool_vm_sku = var.vm_size
  node_pools               = var.node_pools

  # Private cluster with Azure AD
  private_dns_zone_id         = data.terraform_remote_state.network.outputs.network_config.private_dns_zone_aks_id
  private_dns_zone_id_enabled = var.private_cluster_enabled
  rbac_aad_tenant_id          = data.azurerm_client_config.current.tenant_id
  rbac_aad_azure_rbac_enabled = true

  # Let the module create and manage its own identity
  managed_identities = {
    system_assigned = false
  }

  # Optional: Container Registry
  acr = var.enable_acr ? {
    name                          = var.acr_name
    subnet_resource_id            = data.terraform_remote_state.network.outputs.network_config.subnet_private_endpoints_id
    private_dns_zone_resource_ids = [data.terraform_remote_state.network.outputs.network_config.private_dns_zone_acr_id]
  } : null

  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}
