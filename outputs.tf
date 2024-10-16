output "config" {
  description = "contains the configuration for the sql managed instance"
  value       = azurerm_mssql_managed_instance.sql
}

output "databases" {
  description = "contains the sql managed instance databases"
  value       = azurerm_mssql_managed_database.databases
}
