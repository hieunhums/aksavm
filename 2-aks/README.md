# Production AKS with Azure Verified Modules

Enterprise-grade Azure Kubernetes Service deployment using Azure Verified Modules (AVM).

## Why Azure Verified Modules?

**60% less code. 100% production-ready.**

One module call provides enterprise features that would normally require hundreds of lines of configuration:

✅ **Security**: Private cluster, Azure RBAC, Azure Policy, Workload Identity
✅ **High Availability**: Zone redundancy, autoscaling, health monitoring
✅ **Networking**: CNI Overlay, Cilium network policy, private endpoints
✅ **Compliance**: Microsoft-maintained, security hardened, audit-ready
✅ **Container Registry**: Integrated ACR with private networking

## Quick Start

### Prerequisites

- Terraform >= 1.9
- Azure CLI authenticated
- Foundation network deployed (1-network)

### Deploy Development

```bash
# Initialize
terraform init -backend-config="../environments/dev/aks.tfvars"

# Deploy
terraform apply -var-file="../environments/dev/aks.tfvars"
```

### Deploy Production

```bash
# Initialize
terraform init -backend-config=environments/prod/backend.tfvars

# Deploy
terraform apply -var-file=environments/prod/terraform.tfvars
```

## What's Included

| Feature | Development | Production |
|---------|-------------|------------|
| **Node Pools** | 2 pools | 3 pools (HA) |
| **VM Size** | D2ds_v5 | D4d_v5 |
| **Kubernetes** | 1.30 + Cilium | 1.30 + Cilium |
| **Private Cluster** | ✅ | ✅ |
| **Azure AD RBAC** | ✅ | ✅ |
| **Auto-scaling** | ✅ | ✅ |
| **Workload Identity** | ✅ | ✅ |
| **Container Registry** | ✅ | ✅ (Geo-redundant) |

## Simple Configuration

Customize via `environments/{env}/terraform.tfvars`:

```hcl
# Core
name     = "aks-prod"
location = "australiaeast"

# Kubernetes
kubernetes_version = "1.30"
network_policy     = "cilium"

# Node pools
vm_size = "Standard_D4d_v5"
node_pools = {
  workload = {
    name      = "workload"
    vm_size   = "Standard_D4d_v5"
    min_count = 3
    max_count = 10
  }
}

# Container Registry
enable_acr = true
acr_name   = "acrprodaks"
```

## Architecture

```
Azure Verified Module
      ↓
Production AKS Cluster
├── Private cluster (VNet integrated)
├── System node pool (3-5 nodes, HA)
├── User node pools (auto-scaled)
├── Azure AD RBAC
├── Workload Identity
└── Integrated ACR
      ↓
Private networking
├── Private DNS zones
├── Private endpoints
└── Managed identity
```

## Connect to Cluster

```bash
# Get credentials
az aks get-credentials --resource-group rg-aks-prod-aue --name aks-prod

# Verify
kubectl get nodes
```

## Key Outputs

- `cluster_id` - AKS resource ID
- `cluster_fqdn` - Cluster endpoint
- `kube_config_raw` - kubectl configuration
- `oidc_issuer_url` - For workload identity

## Module Reference

- **Source**: `Azure/avm-ptn-aks-production/azurerm`
- **Version**: `~> 0.1`
- **Docs**: [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
