# PostgreSQL Flexible Server with Azure Verified Modules

Enterprise-grade Azure Database for PostgreSQL Flexible Server deployment using Azure Verified Modules (AVM).

## Why Azure Verified Modules?

**Simple configuration. Enterprise features.**

Deploy a production-ready PostgreSQL database with minimal code:

✅ **Security**: Private networking, Azure AD authentication, automated backups
✅ **High Availability**: Zone-redundant configuration (optional)
✅ **Compliance**: Microsoft-maintained, security hardened
✅ **Integration**: Seamless AKS connectivity via private endpoints
✅ **Management**: Automated backups, point-in-time restore

## Quick Start

### Prerequisites

- Terraform >= 1.9
- Azure CLI authenticated
- Foundation network deployed (1-network)
- Storage Blob Data Contributor role assigned

### Deploy Development

```bash
# Initialize
terraform init

# Deploy
terraform apply -var-file="../environments/dev/postgresql.tfvars"
```

### Deploy Production

```bash
# Initialize
terraform init

# Deploy with HA
terraform apply -var-file=environments/prod/postgresql.tfvars
```

## What's Included

| Feature | Development | Production |
|---------|-------------|------------|
| **SKU** | GP_Standard_D2s_v3 | GP_Standard_D4s_v3 |
| **Storage** | 32 GB | 128 GB |
| **PostgreSQL Version** | 16 | 16 |
| **High Availability** | Disabled | ZoneRedundant |
| **Backup Retention** | 7 days | 35 days |
| **Geo-Redundant Backup** | ❌ | ✅ |
| **Azure AD Auth** | ✅ | ✅ |
| **Private Network** | ✅ | ✅ |

## Configuration

Customize via `environments/{env}/postgresql.tfvars`:

```hcl
# PostgreSQL Server
name               = "psql-prod-australiaeast"
sku_name           = "GP_Standard_D4s_v3"
storage_mb         = 131072  # 128 GB
postgresql_version = "16"

# High Availability
high_availability_mode    = "ZoneRedundant"
standby_availability_zone = "2"

# Authentication
administrator_login = "pgadmin"
# Password auto-generated if not provided

authentication = {
  active_directory_auth_enabled = true
  password_auth_enabled         = true
}

# Network (Private)
public_network_access_enabled = false

# Backup
backup_retention_days        = 35
geo_redundant_backup_enabled = true

# Databases
databases = {
  app_db = {
    charset   = "UTF8"
    collation = "en_US.utf8"
  }
  analytics_db = {
    charset   = "UTF8"
    collation = "en_US.utf8"
  }
}
```

## Architecture

```
PostgreSQL Flexible Server
├── Private networking (VNet integrated)
├── Private DNS zone
├── Azure AD authentication
├── Automated backups
├── High availability (optional)
└── Multiple databases
      ↓
Connected to AKS
├── Private endpoint
├── Private DNS resolution
└── Workload identity (optional)
```

## Network Integration

The PostgreSQL server is deployed with:

- **Private Access**: No public internet exposure
- **VNet Integration**: Connected to the foundation network
- **Private DNS**: Automatic DNS resolution within VNet
- **AKS Access**: Pods can connect via private endpoint

### Connection String

From within the VNet (e.g., AKS pods):

```bash
# Format
Host: <server-name>.postgres.database.azure.com
Port: 5432
Database: app_db
Username: <admin-user>@<server-name>
SSL Mode: require

# Example
psql "host=psql-dev-australiaeast.postgres.database.azure.com port=5432 dbname=app_db user=pgadmin sslmode=require"
```

## Authentication Options

### 1. Password Authentication (Default)

Password is auto-generated and stored in Terraform state:

```bash
# Get password from Terraform output
terraform output -raw administrator_password
```

### 2. Azure AD Authentication (Recommended)

Configure Azure AD users/groups:

```bash
# Set AAD admin
az postgres flexible-server ad-admin create \
  --resource-group rg-postgresql-dev \
  --server-name psql-dev-australiaeast \
  --display-name "AKS Database Admins" \
  --object-id <aad-group-id>
```

### 3. Workload Identity (From AKS)

Enable pods to authenticate using workload identity:

1. Create Azure AD application
2. Configure federated identity credential with AKS OIDC
3. Grant database permissions to the identity

## High Availability

### Development (Disabled)
- Single zone deployment
- Automatic backups for point-in-time restore
- 99.9% SLA

### Production (ZoneRedundant)
- Primary in Zone 1
- Standby in Zone 2
- Automatic failover (<120 seconds)
- 99.95% SLA

```hcl
high_availability_mode    = "ZoneRedundant"
standby_availability_zone = "2"
```

## Backup & Recovery

### Automated Backups

- **Full Backup**: Daily
- **Transaction Logs**: Continuous
- **Retention**: 7-35 days (configurable)
- **Geo-Redundant**: Optional (production)

### Point-in-Time Restore

Restore to any point within retention period:

```bash
az postgres flexible-server restore \
  --resource-group rg-postgresql-dev \
  --name psql-dev-australiaeast-restored \
  --source-server psql-dev-australiaeast \
  --restore-time "2025-11-20T10:00:00Z"
```

## Monitoring

### Built-in Metrics

- CPU percentage
- Memory percentage
- Storage percentage
- Active connections
- Failed connections
- Replication lag (HA mode)

### Diagnostic Settings

Automatically configured for:
- PostgreSQL logs
- Query performance insights
- Slow query logs
- Connection logs

Access via Log Analytics:

```kusto
AzureDiagnostics
| where ResourceType == "POSTGRESQLFLEXIBLESERVERS"
| where Category == "PostgreSQLLogs"
| where TimeGenerated > ago(1h)
```

## Security Best Practices

### Network Security
- ✅ Disable public access
- ✅ Use private endpoints
- ✅ Enable SSL/TLS enforcement
- ✅ Use private DNS zones

### Authentication
- ✅ Use Azure AD authentication when possible
- ✅ Rotate passwords regularly
- ✅ Use strong passwords (auto-generated)
- ✅ Enable MFA for admin accounts

### Data Protection
- ✅ Enable geo-redundant backups (production)
- ✅ Test restore procedures regularly
- ✅ Enable encryption at rest (automatic)
- ✅ Enable encryption in transit (SSL required)

## Connecting from AKS

### Example: Python Application

```python
import psycopg2
from azure.identity import DefaultAzureCredential

# Using password authentication
conn = psycopg2.connect(
    host="psql-dev-australiaeast.postgres.database.azure.com",
    database="app_db",
    user="pgadmin",
    password="<password>",
    sslmode="require"
)

# Using Azure AD authentication (with managed identity)
credential = DefaultAzureCredential()
token = credential.get_token("https://ossrdbms-aad.database.windows.net/.default")

conn = psycopg2.connect(
    host="psql-dev-australiaeast.postgres.database.azure.com",
    database="app_db",
    user="<aad-user>@<tenant>",
    password=token.token,
    sslmode="require"
)
```

### Kubernetes Secret

```bash
# Create secret with connection details
kubectl create secret generic postgresql-secret \
  --from-literal=host=psql-dev-australiaeast.postgres.database.azure.com \
  --from-literal=database=app_db \
  --from-literal=username=pgadmin \
  --from-literal=password=<password>
```

### Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        env:
        - name: DB_HOST
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: host
        - name: DB_NAME
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: database
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgresql-secret
              key: password
```

## Maintenance

### Server Parameters

Configure server parameters via Terraform:

```hcl
module "postgresql" {
  # ... other config ...
  
  server_configurations = {
    max_connections = "200"
    shared_buffers  = "256MB"
    work_mem        = "16MB"
  }
}
```

### Maintenance Window

Schedule maintenance window:

```bash
az postgres flexible-server update \
  --resource-group rg-postgresql-dev \
  --name psql-dev-australiaeast \
  --maintenance-window day=0 start-hour=2 start-minute=0
```

## Cost Optimization

### Development
- Use smaller SKU (D2s_v3)
- Single zone deployment
- 7-day backup retention
- No geo-redundant backups

**Estimated Cost**: ~$100-150/month

### Production
- Scale up SKU as needed (D4s_v3+)
- Enable zone redundancy
- 35-day backup retention
- Geo-redundant backups

**Estimated Cost**: ~$300-600/month

### Cost-Saving Tips
- Stop server during non-business hours (dev/test)
- Use burstable SKU for non-production
- Right-size based on actual usage
- Enable storage auto-grow

## Troubleshooting

### Connection Issues

```bash
# Test connectivity from AKS
kubectl run -it --rm postgres-test --image=postgres:16 --restart=Never -- \
  psql "host=psql-dev-australiaeast.postgres.database.azure.com port=5432 dbname=app_db user=pgadmin sslmode=require"
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Cannot connect | Check firewall rules, verify private DNS |
| Authentication failed | Verify credentials, check Azure AD admin |
| SSL error | Ensure `sslmode=require` in connection string |
| High CPU/Memory | Scale up SKU, optimize queries |
| Storage full | Enable storage auto-grow, increase storage |

### Logs

```bash
# View server logs
az postgres flexible-server server-logs list \
  --resource-group rg-postgresql-dev \
  --name psql-dev-australiaeast

# Download specific log
az postgres flexible-server server-logs download \
  --resource-group rg-postgresql-dev \
  --name psql-dev-australiaeast \
  --log-file-name <log-file>
```

## Key Outputs

After deployment, Terraform provides:

- `server_id` - PostgreSQL server resource ID
- `server_fqdn` - Server FQDN for connections
- `administrator_password` - Auto-generated password (if not provided)
- `databases` - List of created databases

```bash
# View outputs
terraform output
```

## Module Reference

- **Source**: `Azure/avm-res-dbforpostgresql-flexibleserver/azurerm`
- **Version**: `~> 0.1`
- **Docs**: [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- **PostgreSQL Docs**: [Azure Database for PostgreSQL](https://learn.microsoft.com/azure/postgresql/)

## Next Steps

1. ✅ Deploy PostgreSQL server
2. ✅ Configure Azure AD authentication
3. ✅ Create databases and schemas
4. ✅ Configure application connection strings
5. ✅ Set up monitoring and alerts
6. ✅ Test backup and restore procedures
7. ✅ Implement security best practices
