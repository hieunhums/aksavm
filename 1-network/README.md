# Network Module - Network Infrastructure

Network infrastructure module managed by the Network Operations team using **Azure Verified Modules (AVM)**.

## Purpose

Creates core networking components required for AKS deployment using the **AVM Virtual Network Module** (`Azure/avm-res-network-virtualnetwork/azurerm`):

- Virtual Network with planned CIDR ranges
- Subnets for AKS nodes and private endpoints (created within AVM module)
- Private DNS zones for AKS and ACR
- User-assigned managed identity for AKS
- Network Security Groups (optional)
- Role assignments

## Prerequisites

- Bootstrap module completed ([0-bootstrap](../0-bootstrap/README.md))
- Backend storage account name from bootstrap outputs
- Azure CLI authenticated
- Network team permissions

## What It Creates

### Resource Group
- `rg-network-{env}` - Network resources container

### Virtual Network
- VNet with configurable CIDR
- Dev: `10.1.0.0/16`
- Prod: `10.10.0.0/16`

### Subnets
- **AKS System Nodes**: `/22` (1024 IPs)
- **AKS User Nodes**: `/22` (1024 IPs) - Production only
- **Private Endpoints**: `/24` (256 IPs)

### Private DNS Zones
- `privatelink.{region}.azmk8s.io` - AKS private cluster
- `privatelink.azurecr.io` - ACR private endpoint

### Managed Identity
- User-assigned identity for AKS cluster
- Private DNS Zone Contributor role

### Network Security Groups
- Basic NSG for AKS subnets (optional)

## Deployment

### Development Environment

```bash
cd 1-network

# Initialize with remote backend
terraform init -backend-config="../environments/dev/backend.tfvars"

# Plan
terraform plan -var-file="../environments/dev/network.tfvars"

# Apply
terraform apply -var-file="../environments/dev/network.tfvars"
```

### Production Environment

```bash
cd 1-network

# Initialize with remote backend
terraform init -backend-config=environments/prod/backend.tfvars

# Plan
terraform plan -var-file=environments/prod/terraform.tfvars

# Apply
terraform apply -var-file=environments/prod/terraform.tfvars
```

## Outputs

The module exports a `network_config` output that contains all IDs needed by the AKS module:

```hcl
network_config = {
  vnet_id                     = "..."
  subnet_aks_system_id        = "..."
  subnet_aks_user_id          = "..."
  subnet_private_endpoints_id = "..."
  private_dns_zone_aks_id     = "..."
  private_dns_zone_acr_id     = "..."
  identity_id                 = "..."
  identity_principal_id       = "..."
  identity_client_id          = "..."
}
```

The AKS module consumes these via remote state:

```hcl
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatedev"
    container_name       = "tfstate"
    key                  = "network/dev/terraform.tfstate"
  }
}
```

## CIDR Planning

### Development (10.1.0.0/16)
```
10.1.0.0/22    - AKS nodes (system + user)
10.1.4.0/24    - Private endpoints
10.1.5.0/24    - Reserved
...
10.1.255.0/24  - Reserved
```

### Production (10.10.0.0/16)
```
10.10.0.0/22   - AKS system nodes
10.10.4.0/22   - AKS user nodes
10.10.8.0/24   - Private endpoints
10.10.9.0/24   - Reserved
...
10.10.255.0/24 - Reserved
```

## Customization

### Adding More Subnets

Edit `main.tf` to add additional subnets:

```hcl
resource "azurerm_subnet" "additional" {
  name                 = "snet-additional"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.1.10.0/24"]
}
```

### VNet Peering

To peer with other VNets (e.g., on-premises):

```hcl
resource "azurerm_virtual_network_peering" "to_hub" {
  name                      = "network-to-hub"
  resource_group_name       = azurerm_resource_group.network.name
  virtual_network_name      = azurerm_virtual_network.this.name
  remote_virtual_network_id = var.hub_vnet_id

  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
```

## Team Ownership

This module is owned and managed by the **Network Operations Team**.

Changes require:
1. Pull request with network team review
2. Approval from network lead
3. Deployment during maintenance window (production)

## Troubleshooting

### Issue: Address space conflicts

Check for overlapping CIDRs with other VNets:

```bash
az network vnet list \
  --query "[].{Name:name, AddressSpace:addressSpace.addressPrefixes}" \
  --output table
```

### Issue: Private DNS zone not resolving

Verify VNet link:

```bash
az network private-dns link vnet show \
  --resource-group rg-network-dev \
  --zone-name privatelink.australiaeast.azmk8s.io \
  --name vnet-dev-aks-link
```

### Issue: Identity permissions not working

Check role assignment:

```bash
az role assignment list \
  --assignee <identity-principal-id> \
  --all
```

## Next Steps

After network is deployed:
1. ✅ Save outputs for AKS team
2. ✅ Verify DNS zones are linked
3. ✅ Proceed to [2-aks](../2-aks/README.md)

## Support

For network-related issues, contact the Network Operations team.
