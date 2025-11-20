# =====================================================
# Subscription Vending Outputs
# =====================================================

output "subscription_id" {
  description = "The subscription ID"
  value       = module.subscription_vending.subscription_id
}

output "subscription_resource_id" {
  description = "The subscription resource ID"
  value       = module.subscription_vending.subscription_resource_id
}

output "management_group_subscription_association_id" {
  description = "The management group subscription association ID"
  value       = module.subscription_vending.management_group_subscription_association_id
}

output "virtual_network_resource_ids" {
  description = "Map of virtual network resource IDs"
  value       = module.subscription_vending.virtual_network_resource_ids
}

output "resource_group_ids" {
  description = "Map of resource group IDs"
  value       = module.subscription_vending.resource_group_ids
}

output "subscription_config" {
  description = "Summary of subscription configuration"
  value = {
    subscription_id      = module.subscription_vending.subscription_id
    display_name         = var.subscription_display_name
    workload             = var.subscription_workload
    management_group_id  = var.subscription_management_group_id
    virtual_networks     = keys(var.virtual_networks)
    resource_groups      = keys(var.resource_groups)
  }
}
