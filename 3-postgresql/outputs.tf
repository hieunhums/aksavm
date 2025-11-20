# =====================================================
# PostgreSQL Outputs
# =====================================================

output "postgresql_id" {
  description = "The ID of the PostgreSQL Flexible Server"
  value       = module.postgresql.resource_id
}

output "postgresql_fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server"
  value       = module.postgresql.fqdn
}

output "postgresql_name" {
  description = "The name of the PostgreSQL Flexible Server"
  value       = module.postgresql.name
}

output "administrator_login" {
  description = "The administrator login"
  value       = var.administrator_login
}

output "administrator_password" {
  description = "The administrator password"
  value       = var.administrator_password != "" ? var.administrator_password : random_password.administrator[0].result
  sensitive   = true
}

output "private_dns_zone_id" {
  description = "The ID of the PostgreSQL private DNS zone"
  value       = var.delegated_subnet_id != null ? azurerm_private_dns_zone.postgresql[0].id : null
}

output "connection_string" {
  description = "PostgreSQL connection string template"
  value       = "postgresql://${var.administrator_login}@${module.postgresql.fqdn}:5432/<database>?sslmode=require"
  sensitive   = true
}
