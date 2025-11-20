# =====================================================
# PostgreSQL Module Configuration - Development
# =====================================================

# Common Configuration
environment                  = "dev"
backend_storage_account_name = "sttfstatedevzvjoj9"
location                     = "australiaeast"
resource_group_name          = "rg-postgresql-dev"

# PostgreSQL Server
name               = "psql-dev-australiaeast"
sku_name           = "GP_Standard_D2s_v3"
storage_mb         = 32768
postgresql_version = "16"
zone               = "1"

# High Availability
high_availability_mode    = "Disabled"
standby_availability_zone = "2"

# Authentication
administrator_login    = "pgadmin"
administrator_password = "" # Leave empty to auto-generate

authentication = {
  active_directory_auth_enabled = true
  password_auth_enabled         = true
  tenant_id                     = null # Will use current tenant
}

# Network Configuration (Private)
delegated_subnet_id           = null # Will use from network state
private_dns_zone_id           = null # Will be created
public_network_access_enabled = false

# Backup Configuration
backup_retention_days        = 7
geo_redundant_backup_enabled = false

# Databases to Create
databases = {
  app_db = {
    name      = "app_db"
    charset   = "UTF8"
    collation = "en_US.utf8"
  }
}

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "Terraform"
  Project     = "AKS-PostgreSQL"
}

enable_telemetry = true
