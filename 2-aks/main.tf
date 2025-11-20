# =====================================================
# Production AKS with Azure Verified Modules (AVM)
# =====================================================

# Network configuration from foundation
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = var.backend_storage_account_name
    container_name       = "tfstate"
    key                  = "network/${var.environment}/terraform.tfstate"
  }
}

# Production-ready AKS cluster with AVM
module "aks_cluster" {
  source  = "Azure/avm-ptn-aks-production/azurerm"
  version = "~> 0.1"

  # Core configuration
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
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

  # Managed identity from foundation
  managed_identities = {
    system_assigned            = false
    user_assigned_resource_ids = [data.terraform_remote_state.network.outputs.network_config.identity_id]
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
