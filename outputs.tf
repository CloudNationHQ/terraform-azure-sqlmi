output "mssql_managed_instance" {
  description = "Contains all sql managed instance configuration"
  value       = azurerm_mssql_managed_instance.this
}

output "databases" {
  description = "Contains all sql managed instance databases"
  value       = azurerm_mssql_managed_database.this
}

output "security_alert_policy" {
  description = "Contains all sql managed instance security alert policy configuration"
  value       = azurerm_mssql_managed_instance_security_alert_policy.this
}

output "vulnerability_assessment" {
  description = "Contains all sql managed instance vulnerability assessment configuration"
  value       = azurerm_mssql_managed_instance_vulnerability_assessment.this
}

output "ad_admin" {
  description = "Contains all sql managed instance active directory administrator configuration"
  value       = azurerm_mssql_managed_instance_active_directory_administrator.this
}
