moved {
  from = azurerm_mssql_managed_instance.sql
  to   = azurerm_mssql_managed_instance.this
}

moved {
  from = azurerm_mssql_managed_database.databases
  to   = azurerm_mssql_managed_database.this
}

moved {
  from = azurerm_mssql_managed_instance_security_alert_policy.policy["default"]
  to   = azurerm_mssql_managed_instance_security_alert_policy.this["this"]
}

moved {
  from = azurerm_mssql_managed_instance_vulnerability_assessment.assessment["default"]
  to   = azurerm_mssql_managed_instance_vulnerability_assessment.this["this"]
}

moved {
  from = azurerm_mssql_managed_instance_active_directory_administrator.sql["ad_admin"]
  to   = azurerm_mssql_managed_instance_active_directory_administrator.this["this"]
}

moved {
  from = azuread_directory_role.reader["ad_admin"]
  to   = azuread_directory_role.this["this"]
}

moved {
  from = azuread_directory_role_assignment.role["ad_admin"]
  to   = azuread_directory_role_assignment.this["this"]
}

moved {
  from = time_sleep.wait_after_directory_role_assignment["ad_admin"]
  to   = time_sleep.this["this"]
}

moved {
  from = data.azurerm_client_config.current
  to   = data.azurerm_client_config.this
}

moved {
  from = data.azuread_service_principal.current["id"]
  to   = data.azuread_service_principal.this["this"]
}

moved {
  from = data.azuread_user.current["id"]
  to   = data.azuread_user.this["this"]
}

moved {
  from = data.azuread_group.current["id"]
  to   = data.azuread_group.this["this"]
}
