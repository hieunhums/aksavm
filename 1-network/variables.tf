# =====================================================
# Foundation Module Variables
# =====================================================

# Required Variables
variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for network resources"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

# Subnet Configuration
variable "subnet_aks_system_name" {
  description = "Name of the AKS system nodes subnet"
  type        = string
  default     = "snet-aks-system"
}

variable "subnet_aks_system_prefixes" {
  description = "Address prefixes for AKS system nodes subnet"
  type        = list(string)
}

variable "create_separate_user_subnet" {
  description = "Create a separate subnet for user node pools"
  type        = bool
  default     = false
}

variable "subnet_aks_user_name" {
  description = "Name of the AKS user nodes subnet"
  type        = string
  default     = "snet-aks-user"
}

variable "subnet_aks_user_prefixes" {
  description = "Address prefixes for AKS user nodes subnet"
  type        = list(string)
  default     = []
}

variable "subnet_private_endpoints_name" {
  description = "Name of the private endpoints subnet"
  type        = string
  default     = "snet-private-endpoints"
}

variable "subnet_private_endpoints_prefixes" {
  description = "Address prefixes for private endpoints subnet"
  type        = list(string)
}

# Identity Configuration
variable "identity_name" {
  description = "Name of the user-assigned managed identity for AKS"
  type        = string
}

# Network Security
variable "create_nsg" {
  description = "Create Network Security Group for AKS subnets"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
