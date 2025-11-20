# =====================================================
# AKS Cluster Outputs
# =====================================================

output "cluster_id" {
  description = "AKS cluster resource ID"
  value       = module.aks_cluster.resource_id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = var.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks_cluster.fqdn
}

output "cluster_private_fqdn" {
  description = "Private cluster FQDN"
  value       = module.aks_cluster.private_fqdn
}

# =====================================================
# Kubeconfig
# =====================================================

output "kube_config_raw" {
  description = "Raw kubeconfig for kubectl access"
  value       = module.aks_cluster.kube_config_raw
  sensitive   = true
}

# =====================================================
# Identity
# =====================================================

output "cluster_identity" {
  description = "AKS cluster identity"
  value = {
    principal_id = module.aks_cluster.identity_principal_id
    tenant_id    = module.aks_cluster.identity_tenant_id
  }
}

output "kubelet_identity" {
  description = "Kubelet managed identity"
  value = {
    client_id = module.aks_cluster.kubelet_identity_client_id
    object_id = module.aks_cluster.kubelet_identity_object_id
  }
}

# =====================================================
# Network
# =====================================================

output "node_resource_group" {
  description = "Node resource group name"
  value       = module.aks_cluster.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = module.aks_cluster.oidc_issuer_url
}

# =====================================================
# Namespaces
# =====================================================

output "namespaces" {
  description = "Created Kubernetes namespaces"
  value       = [for ns in kubernetes_namespace.namespaces : ns.metadata[0].name]
}
