output "config" {
  description = "Contains all sql managed instance configuration"
  value       = azurerm_mssql_managed_instance.sql
}

output "databases" {
  description = "Contains all sql managed instance databases"
  value       = azurerm_mssql_managed_database.databases
}
