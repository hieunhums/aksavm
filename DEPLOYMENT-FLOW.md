# AKS Deployment Flow

## Overview
This repository deploys a production-ready Azure Kubernetes Service (AKS) cluster using a modular, sequential approach with Terraform remote state management.

---

## Deployment Flowchart

```mermaid
flowchart TD
    Start([Start Deployment]) --> Bootstrap
    
    subgraph Bootstrap["0-bootstrap"]
        B1[Initialize local backend]
        B2[Create Resource Group<br/>rg-terraform-state]
        B3[Create Storage Account<br/>sttfstatedev******]
        B4[Create Blob Container<br/>tfstate]
        B5[Configure Azure AD Auth<br/>Disable key-based auth]
        B1 --> B2 --> B3 --> B4 --> B5
    end
    
    Bootstrap --> |"Outputs:<br/>storage_account_name"| Network
    
    subgraph Network["1-network"]
        N1[Configure remote backend<br/>backend.tfvars]
        N2[Assign Storage Blob<br/>Data Contributor role]
        N3[terraform init with<br/>Azure AD auth]
        N4[Create VNet + Subnets<br/>10.0.0.0/16]
        N5[Create Private DNS Zones<br/>AKS & ACR]
        N6[Create Managed Identity<br/>for AKS]
        N7[Configure NSG]
        N1 --> N2 --> N3 --> N4 --> N5 --> N6 --> N7
    end
    
    Network --> |"State: network.tfstate<br/>Outputs: network_config"| AKS
    
    subgraph AKS["2-aks"]
        A1[Read network state<br/>via remote_state]
        A2[Enable subscription features<br/>EncryptionAtHost]
        A3[Create Resource Group<br/>rg-aks-dev]
        A4[Deploy AKS Cluster<br/>v1.31 + Cilium]
        A5[Configure Private Cluster<br/>with Azure AD RBAC]
        A6[Create System Node Pool<br/>3-9 nodes, autoscale]
        A7[Create User Node Pool<br/>1-3 nodes, autoscale]
        A8[Setup Log Analytics<br/>& Monitoring]
        A9[Configure Workload Identity<br/>& OIDC]
        A1 --> A2 --> A3 --> A4 --> A5 --> A6 --> A7 --> A8 --> A9
    end
    
    AKS --> Complete([Deployment Complete])
    
    Complete --> Access
    
    subgraph Access["Access Cluster"]
        AC1[az aks get-credentials]
        AC2[kubectl get nodes]
    end
    
    style Bootstrap fill:#e1f5ff
    style Network fill:#fff4e1
    style AKS fill:#e8f5e9
    style Access fill:#f3e5f5
```

---

## Detailed Step-by-Step Flow

### Phase 1: Bootstrap (0-bootstrap)
**Purpose**: Create remote state storage for all modules

```bash
cd 0-bootstrap
terraform init                    # Local backend
terraform apply -var environment=dev
```

**Creates**:
- Resource Group: `rg-terraform-state`
- Storage Account: `sttfstatedevXXXXXX` (random suffix)
- Container: `tfstate`
- Azure AD authentication enabled (key-based auth disabled)

**Outputs**:
- `storage_account_name` → Used by all subsequent modules

---

### Phase 2: Network Foundation (1-network)
**Purpose**: Create network infrastructure and prerequisites

```bash
cd ../1-network

# 1. Create backend config
cat > ../environments/dev/backend.tfvars <<EOF
resource_group_name  = "rg-terraform-state"
storage_account_name = "sttfstatedevXXXXXX"
container_name       = "tfstate"
key                  = "network.tfstate"
use_azuread_auth     = true
EOF

# 2. Assign storage permissions
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --scope "/subscriptions/.../storageAccounts/sttfstatedevXXXXXX"

# 3. Initialize with remote backend
terraform init -backend-config="../environments/dev/backend.tfvars"

# 4. Deploy network infrastructure
terraform apply -var-file="../environments/dev/network.tfvars"
```

**Creates**:
- Resource Group: `rg-aks-network-dev`
- Virtual Network: `vnet-aks-dev` (10.0.0.0/16)
- Subnets:
  - `snet-aks-system` (10.0.0.0/22)
  - `snet-private-endpoints` (10.0.4.0/24)
- Private DNS Zones:
  - `privatelink.australiaeast.azmk8s.io`
  - `privatelink.azurecr.io`
- Managed Identity: `id-aks-dev`
- Network Security Group (optional)

**State File**: `tfstate/network.tfstate`

**Outputs** → `network_config`:
- VNet ID, Subnet IDs
- Private DNS Zone IDs
- Managed Identity ID

---

### Phase 3: AKS Deployment (2-aks)
**Purpose**: Deploy production AKS cluster using Azure Verified Modules

```bash
cd ../2-aks

# 1. Enable required features
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
az provider register -n Microsoft.Compute

# 2. Initialize (shares same backend as network)
terraform init

# 3. Deploy AKS
terraform apply -var-file="../environments/dev/aks.tfvars"
```

**Reads Remote State**:
- `network.tfstate` → Gets VNet, subnets, DNS zones, identity

**Creates**:
- Resource Group: `rg-aks-dev`
- AKS Cluster: `aks-aks-dev-australiaeast`
  - Kubernetes: v1.31
  - Network Policy: Cilium
  - CNI: Azure Overlay (pods: 10.244.0.0/16)
  - Service CIDR: 10.245.0.0/16
- Node Pools:
  - System: 3-9 nodes, Standard_D4d_v5
  - User: 1-3 nodes, Standard_D4d_v5
- User-Assigned Identity: `uami-aks`
- Log Analytics Workspace
- Diagnostic Settings
- Role Assignments:
  - Network Contributor on network RG
  - Private DNS Zone Contributor

**State File**: `tfstate/aks.tfstate` (separate from network)

**Outputs**:
- `cluster_id`, `cluster_fqdn`
- `kube_config_raw`
- `oidc_issuer_url`

---

## State Management Flow

```mermaid
flowchart LR
    subgraph Storage["Azure Storage Account"]
        direction TB
        C1[Container: tfstate]
        S1[network.tfstate]
        S2[aks.tfstate]
        S3[postgresql.tfstate]
        C1 --> S1
        C1 --> S2
        C1 --> S3
    end
    
    N[1-network] -->|writes| S1
    A[2-aks] -->|reads| S1
    A -->|writes| S2
    P[3-postgresql] -->|reads| S1
    P -->|reads| S2
    P -->|writes| S3
    
    style Storage fill:#e3f2fd
    style S1 fill:#fff9c4
    style S2 fill:#fff9c4
    style S3 fill:#fff9c4
```

---

## Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant AzureCLI
    participant Storage
    participant Terraform
    
    User->>AzureCLI: az login
    AzureCLI-->>User: Token
    
    User->>AzureCLI: Assign Storage Blob Data Contributor
    AzureCLI->>Storage: Create role assignment
    
    User->>Terraform: terraform init -backend-config
    Terraform->>Storage: Authenticate with Azure AD
    Storage-->>Terraform: Access granted
    
    User->>Terraform: terraform apply
    Terraform->>Storage: Read/write state with Azure AD auth
    Storage-->>Terraform: State data
```

---

## Configuration Files Structure

```
aksavm/
├── 0-bootstrap/
│   ├── main.tf              # Bootstrap resources
│   ├── variables.tf         # Environment variable
│   └── terraform.tfstate    # LOCAL state only
│
├── 1-network/
│   ├── main.tf              # Network resources + AVM module
│   ├── variables.tf         # Network configuration
│   ├── versions.tf          # Backend: azurerm (remote)
│   └── outputs.tf           # network_config output
│
├── 2-aks/
│   ├── main.tf              # AKS + remote state data source
│   ├── variables.tf         # AKS configuration
│   ├── versions.tf          # Backend: azurerm (remote)
│   ├── locals.tf            # Azure client config
│   └── outputs.tf           # Cluster outputs
│
└── environments/
    └── dev/
        ├── backend.tfvars   # Shared backend config
        ├── network.tfvars   # Network variables
        └── aks.tfvars       # AKS variables
```

---

## Key Dependencies

```mermaid
graph TD
    B[0-bootstrap<br/>Storage Account] --> N
    N[1-network<br/>VNet + DNS + Identity] --> A
    A[2-aks<br/>AKS Cluster] --> P
    P[3-postgresql<br/>Database]
    
    B -.->|storage_account_name| N
    N -.->|network_config| A
    N -.->|network_config| P
    A -.->|cluster info| P
    
    style B fill:#bbdefb
    style N fill:#fff9c4
    style A fill:#c8e6c9
    style P fill:#f8bbd0
```

---

## Variables Flow

### Bootstrap → Network
```
backend_config (from bootstrap output)
  ↓
environments/dev/backend.tfvars
  ↓
terraform init -backend-config
```

### Network → AKS
```
network.tfstate (remote state)
  ↓
data.terraform_remote_state.network
  ↓
outputs.network_config {
  subnet_aks_system_id
  private_dns_zone_aks_id
  identity_id
}
  ↓
module.aks_cluster inputs
```

---

## Troubleshooting Flow

```mermaid
flowchart TD
    E1{Error?} -->|Key-based auth<br/>not permitted| Fix1[Add storage_use_azuread = true<br/>to provider]
    E1 -->|403 Forbidden| Fix2[Assign Storage Blob<br/>Data Contributor role]
    E1 -->|State file not found| Fix3[Check state key path<br/>in remote_state config]
    E1 -->|K8s version not supported| Fix4[Update to supported version<br/>e.g., 1.31]
    E1 -->|EncryptionAtHost error| Fix5[Enable feature:<br/>az feature register]
    E1 -->|Identity not found| Fix6[Ensure network module<br/>deployed first]
    
    Fix1 --> Success([Retry])
    Fix2 --> Success
    Fix3 --> Success
    Fix4 --> Success
    Fix5 --> Success
    Fix6 --> Success
    
    style E1 fill:#ffebee
    style Success fill:#c8e6c9
```

---

## Summary

1. **Bootstrap**: Creates shared remote state storage (run once)
2. **Network**: Creates foundation infrastructure, stores state remotely
3. **AKS**: Reads network state, deploys cluster
4. **Access**: Use Azure CLI to get kubeconfig and access cluster

All modules use Azure AD authentication for state storage (no access keys needed).
