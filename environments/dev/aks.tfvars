# =====================================================
# AKS Module Configuration - Development
# =====================================================

# Core Configuration
environment                  = "dev"
backend_storage_account_name = "sttfstatedevzvjoj9"

# AKS Cluster
name                = "aks-dev-australiaeast"
location            = "australiaeast"
resource_group_name = "rg-aks-dev"

# Kubernetes Configuration
kubernetes_version = "1.31"
network_policy     = "cilium"

# Network Configuration (CNI Overlay)
pod_cidr             = "10.244.0.0/16"
service_cidr         = "10.245.0.0/16"
dns_service_ip       = "10.245.0.10"
private_cluster_enabled = true

# Default Node Pool
vm_size = "Standard_D4d_v5"

# Additional User Node Pools
node_pools = {
  user = {
    name      = "user"
    orchestrator_version = "1.31"
    vm_size   = "Standard_D4d_v5"
    min_count = 1
    max_count = 3
  }
}

# Container Registry
enable_acr = false
acr_name   = null

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "AKS"
}

enable_telemetry = true
