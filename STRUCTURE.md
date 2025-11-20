# Enterprise Infrastructure Structure

## Overview

This repository contains Terraform modules for deploying production-grade Azure Kubernetes Service (AKS) infrastructure with enterprise separation of concerns.

```
aksavm/
│
├── 0-bootstrap/              # DevOps Team (One-time)
│   ├── main.tf              # Creates Terraform state storage
│   └── README.md
│
├── 1-foundation/            # Network Team (Per environment)
│   ├── main.tf              # VNet, Subnets, DNS, Identities
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   └── environments/
│       ├── dev/
│       │   ├── backend.tfvars
│       │   └── terraform.tfvars
│       └── prod/
│           ├── backend.tfvars
│           └── terraform.tfvars
│
└── 2-aks/                   # Platform Team (Per environment)
    ├── main.tf              # AKS using AVM pattern
    ├── variables.tf
    ├── outputs.tf
    ├── locals.tf
    ├── versions.tf
    ├── examples/            # Reference implementations
    │   ├── dev/
    │   └── prod/
    └── environments/        # Real deployments
        ├── dev/
        │   ├── backend.tfvars
        │   └── terraform.tfvars
        └── prod/
            ├── backend.tfvars
            └── terraform.tfvars
```

## Module Purposes

### 0-bootstrap
**Owner**: DevOps/Platform Engineering
**Runs**: Once per subscription
**Creates**:
- Resource group for Terraform state
- Storage account (GRS, encrypted)
- Storage container for state files

**State**: Local (bootstrap.tfstate kept locally or in secure vault)

### 1-foundation
**Owner**: Network Team
**Runs**: Once per environment (dev/staging/prod)
**Creates**:
- Virtual Network with CIDR planning
- Subnets (AKS nodes, private endpoints)
- Network Security Groups
- Private DNS zones (AKS, ACR)
- User-assigned managed identities
- Role assignments
- Network peering (if applicable)

**State**: Remote (in bootstrap storage account)
**Outputs**: Network IDs consumed by AKS module

### 2-aks
**Owner**: Platform/AKS Team
**Runs**: Once per environment
**Creates**:
- AKS cluster (private, CNI Overlay)
- Node pools (system, user, ingress)
- Azure Container Registry (private)
- Log Analytics workspace
- Azure Monitor integration
- Diagnostic settings

**State**: Remote (in bootstrap storage account)
**Inputs**: Consumes foundation outputs via remote state

## Deployment Flow

```
┌─────────────────┐
│  0-bootstrap    │  Run once
│  (Local state)  │  Creates: Storage Account
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  1-foundation   │  Per environment
│  (Remote state) │  Creates: Network infra
└────────┬────────┘
         │
         │ Outputs: subnet_ids, dns_zone_ids
         │
         ▼
┌─────────────────┐
│  2-aks          │  Per environment
│  (Remote state) │  Creates: AKS cluster
└─────────────────┘
         │
         │ Uses: data.terraform_remote_state
         ▼
     AKS Cluster
```

## State Management

### Bootstrap State (Local)
```
0-bootstrap/terraform.tfstate
```
Keep this file in:
- Secure vault (HashiCorp Vault, Azure Key Vault)
- Git (encrypted with git-crypt or similar)
- Backup location

### Foundation & AKS State (Remote)
```
Storage Account: sttfstatedev
└── Container: tfstate
    ├── foundation/
    │   ├── dev/terraform.tfstate
    │   ├── staging/terraform.tfstate
    │   └── prod/terraform.tfstate
    └── aks/
        ├── dev/terraform.tfstate
        ├── staging/terraform.tfstate
        └── prod/terraform.tfstate
```

## Team Workflow

### DevOps Team (Bootstrap)
```bash
cd 0-bootstrap
terraform init
terraform apply -var environment=dev
# Save outputs for network and platform teams
```

### Network Team (Foundation)
```bash
cd 1-foundation
terraform init -backend-config=environments/dev/backend.tfvars
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
# Outputs consumed by AKS team
```

### Platform Team (AKS)
```bash
cd 2-aks
terraform init -backend-config=environments/dev/backend.tfvars
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

## Benefits for NAB

### 1. Compliance & Audit
- ✅ Everything as code
- ✅ Git history for all changes
- ✅ PR-based approval workflows
- ✅ Clear ownership boundaries

### 2. Team Autonomy
- ✅ Network team controls networking
- ✅ Platform team controls AKS
- ✅ No cross-team dependencies for changes
- ✅ Independent deployment cycles

### 3. Disaster Recovery
- ✅ Reproducible infrastructure
- ✅ Multi-region deployment ready
- ✅ State files geo-replicated
- ✅ Consistent patterns across clouds

### 4. Multi-Cloud Ready
Same pattern works for:
- AWS: VPC → EKS
- GCP: VPC → GKE
- Azure: VNet → AKS

### 5. Change Management
```
Network Change:
  1-foundation PR → Review → Merge → Deploy
  No impact on AKS

AKS Change:
  2-aks PR → Review → Merge → Deploy
  No impact on network
```

## Security Posture

### State File Security
- ✅ Encrypted at rest (infrastructure encryption)
- ✅ TLS 1.2+ in transit
- ✅ No public access
- ✅ Geo-redundant backups
- ✅ Soft delete enabled (30 days)
- ✅ Versioning enabled

### Network Security
- ✅ Private AKS API server
- ✅ Private DNS zones
- ✅ Network Security Groups
- ✅ Private endpoints for ACR
- ✅ No public IPs

### Identity Security
- ✅ Managed identities (no service principals)
- ✅ Azure AD integration
- ✅ RBAC at all levels
- ✅ Workload identity for pods

## Multi-Region Strategy

For DR across Australia East + Southeast:

```
Region: Australia East (Primary)
├── 0-bootstrap (shared)
├── 1-foundation-aue
│   └── State: foundation/prod-aue/terraform.tfstate
└── 2-aks-aue
    └── State: aks/prod-aue/terraform.tfstate

Region: Australia Southeast (DR)
├── 0-bootstrap (shared)
├── 1-foundation-ase
│   └── State: foundation/prod-ase/terraform.tfstate
└── 2-aks-ase
    └── State: aks/prod-ase/terraform.tfstate

ACR: Geo-replicated between regions
```

## CI/CD Integration

### Azure DevOps Pipeline Structure
```yaml
pipelines/
├── 00-bootstrap.yml        # Manual trigger only
├── 01-foundation-dev.yml   # Network team
├── 01-foundation-prod.yml  # Network team
├── 02-aks-dev.yml          # Platform team
└── 02-aks-prod.yml         # Platform team
```

### Approval Gates
- Foundation (dev): Auto-deploy on PR merge
- Foundation (prod): Manual approval required
- AKS (dev): Auto-deploy on PR merge
- AKS (prod): Manual approval + testing required

## Cost Allocation

Tags propagate through modules:
```hcl
tags = {
  Environment = "Production"
  Team        = "Platform"
  CostCenter  = "Infrastructure"
  Application = "AKS"
}
```

Cost breakdown:
- Bootstrap: ~$5/month (storage)
- Foundation: ~$50/month (VNet, DNS, NSG)
- AKS (dev): ~$500/month
- AKS (prod): ~$2000/month

## Next Steps

1. **Deploy Bootstrap** → [0-bootstrap/README.md](0-bootstrap/README.md)
2. **Deploy Foundation** → [1-foundation/README.md](1-foundation/README.md)
3. **Deploy AKS** → [2-aks/README.md](2-aks/README.md)

## Support

- Technical questions: Platform Engineering team
- Network changes: Network Operations team
- Access requests: Identity & Access Management team
