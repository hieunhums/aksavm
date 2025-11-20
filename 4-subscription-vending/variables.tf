# =====================================================
# Subscription Vending Variables
# =====================================================

variable "subscription_alias_enabled" {
  description = "Enable subscription creation via alias"
  type        = bool
  default     = true
}

variable "subscription_billing_scope" {
  description = "Billing scope for the subscription (EA enrollment account or MCA billing profile)"
  type        = string
}

variable "subscription_display_name" {
  description = "Display name for the subscription"
  type        = string
}

variable "subscription_alias_name" {
  description = "Alias name for the subscription"
  type        = string
}

variable "subscription_workload" {
  description = "Workload type (Production or DevTest)"
  type        = string
  default     = "Production"

  validation {
    condition     = contains(["Production", "DevTest"], var.subscription_workload)
    error_message = "Workload must be Production or DevTest."
  }
}

# =====================================================
# Management Group Association
# =====================================================

variable "subscription_management_group_association_enabled" {
  description = "Enable management group association"
  type        = bool
  default     = true
}

variable "subscription_management_group_id" {
  description = "Management group ID to associate with"
  type        = string
  default     = ""
}

# =====================================================
# Existing Subscription (alternative to creating new)
# =====================================================

variable "subscription_id" {
  description = "Existing subscription ID (if not creating new)"
  type        = string
  default     = ""
}

# =====================================================
# Virtual Network Configuration
# =====================================================

variable "virtual_network_enabled" {
  description = "Enable virtual network creation"
  type        = bool
  default     = true
}

variable "virtual_networks" {
  description = "Map of virtual networks to create"
  type = map(object({
    name                    = string
    address_space           = list(string)
    location                = string
    resource_group_name     = string
    hub_peering_enabled     = optional(bool, false)
    hub_network_resource_id = optional(string, "")
    mesh_peering_enabled    = optional(bool, false)
  }))
  default = {}
}

# =====================================================
# Role Assignments
# =====================================================

variable "role_assignment_enabled" {
  description = "Enable role assignments"
  type        = bool
  default     = true
}

variable "role_assignments" {
  description = "Map of role assignments"
  type = map(object({
    principal_id         = string
    definition           = string
    relative_scope       = optional(string, "")
    condition            = optional(string, "")
    condition_version    = optional(string, "")
    delegated_managed_identity_resource_id = optional(string, "")
  }))
  default = {}
}

# =====================================================
# Resource Groups
# =====================================================

variable "resource_group_creation_enabled" {
  description = "Enable resource group creation"
  type        = bool
  default     = true
}

variable "resource_groups" {
  description = "Map of resource groups to create"
  type = map(object({
    name     = string
    location = string
    tags     = optional(map(string), {})
  }))
  default = {}
}

# =====================================================
# Budget & Cost Management
# =====================================================

variable "budget_enabled" {
  description = "Enable budget creation"
  type        = bool
  default     = false
}

variable "budgets" {
  description = "Map of budgets to create"
  type = map(object({
    amount     = number
    time_grain = optional(string, "Monthly")
    time_period = object({
      start_date = string
      end_date   = optional(string)
    })
    notifications = optional(map(object({
      enabled        = bool
      threshold      = number
      operator       = string
      contact_emails = optional(list(string), [])
      contact_roles  = optional(list(string), [])
      contact_groups = optional(list(string), [])
    })), {})
  }))
  default = {}
}

# =====================================================
# Tags
# =====================================================

variable "subscription_tags" {
  description = "Tags to apply to the subscription"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "location" {
  description = "Default Azure region"
  type        = string
  default     = "australiaeast"
}

# =====================================================
# Telemetry
# =====================================================

variable "enable_telemetry" {
  description = "Enable telemetry for AVM module"
  type        = bool
  default     = true
}
