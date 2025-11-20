# =====================================================
# Common Variables
# =====================================================

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "australiaeast"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "backend_storage_account_name" {
  description = "Storage account name for Terraform state"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

# =====================================================
# PostgreSQL Configuration
# =====================================================

variable "name" {
  description = "Name of the PostgreSQL Flexible Server"
  type        = string
}

variable "sku_name" {
  description = "SKU name for PostgreSQL server (e.g., GP_Standard_D2s_v3)"
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "storage_mb" {
  description = "Storage size in MB"
  type        = number
  default     = 32768
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "1"
}

# =====================================================
# High Availability
# =====================================================

variable "high_availability_mode" {
  description = "High availability mode (Disabled, SameZone, ZoneRedundant)"
  type        = string
  default     = "Disabled"
}

variable "standby_availability_zone" {
  description = "Standby availability zone for HA"
  type        = string
  default     = "2"
}

# =====================================================
# Authentication
# =====================================================

variable "administrator_login" {
  description = "Administrator login for PostgreSQL"
  type        = string
  default     = "pgadmin"
}

variable "administrator_password" {
  description = "Administrator password (leave empty to auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "authentication" {
  description = "Authentication configuration"
  type = object({
    active_directory_auth_enabled = optional(bool, true)
    password_auth_enabled         = optional(bool, true)
    tenant_id                     = optional(string)
  })
  default = {}
}

# =====================================================
# Network Configuration
# =====================================================

variable "delegated_subnet_id" {
  description = "Subnet ID for PostgreSQL delegation (for private access)"
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for PostgreSQL"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

# =====================================================
# Backup Configuration
# =====================================================

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = false
}

# =====================================================
# Databases
# =====================================================

variable "databases" {
  description = "Map of databases to create"
  type = map(object({
    name      = string
    charset   = optional(string, "UTF8")
    collation = optional(string, "en_US.utf8")
  }))
  default = {}
}

# =====================================================
# Diagnostic Settings
# =====================================================

variable "enable_telemetry" {
  description = "Enable telemetry for AVM module"
  type        = bool
  default     = true
}
