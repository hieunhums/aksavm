# =====================================================
# Core Configuration
# =====================================================

variable "environment" {
  description = "Environment (dev/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Must be 'dev' or 'prod'"
  }
}

variable "backend_storage_account_name" {
  description = "Terraform state storage account"
  type        = string
}

variable "name" {
  description = "AKS cluster name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

# =====================================================
# Kubernetes Configuration
# =====================================================

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "network_policy" {
  description = "Network policy (cilium/calico/azure)"
  type        = string
  default     = "cilium"
}

# =====================================================
# Network Configuration
# =====================================================

variable "pod_cidr" {
  description = "Pod CIDR for CNI Overlay"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.0.0.10"
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}

# =====================================================
# Node Pool Configuration
# =====================================================

variable "vm_size" {
  description = "Default node pool VM size"
  type        = string
  default     = "Standard_D4d_v5"
}

variable "node_pools" {
  description = "Additional user node pools"
  type = map(object({
    name      = string
    orchestrator_version = string
    vm_size   = string
    min_count = number
    max_count = number
  }))
  default = {}
}

# =====================================================
# Container Registry
# =====================================================

variable "enable_acr" {
  description = "Enable Azure Container Registry"
  type        = bool
  default     = false
}

variable "acr_name" {
  description = "ACR name (if enabled)"
  type        = string
  default     = null
}

# =====================================================
# Kubernetes Namespaces
# =====================================================

variable "namespaces" {
  description = "Kubernetes namespaces to create (applied post-deployment)"
  type = list(object({
    name   = string
    labels = map(string)
  }))
  default = []
}

# =====================================================
# Tags
# =====================================================

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "enable_telemetry" {
  description = "Enable module telemetry"
  type        = bool
  default     = true
}
