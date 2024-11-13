# managed instance
resource "azurerm_mssql_managed_instance" "sql" {
  resource_group_name            = coalesce(try(var.config.resource_group, null), var.resource_group)
  location                       = coalesce(try(var.config.location, null), var.location)
  name                           = var.config.name
  sku_name                       = var.config.sku_name
  license_type                   = try(var.config.license_type, "LicenseIncluded")
  administrator_login            = try(var.config.administrator_login, "adminLogin")
  administrator_login_password   = var.config.administrator_login_password
  storage_size_in_gb             = var.config.storage_size_in_gb
  subnet_id                      = var.config.subnet_id
  vcores                         = var.config.vcores
  collation                      = try(var.config.collation, "SQL_Latin1_General_CP1_CI_AS")
  dns_zone_partner_id            = try(var.config.dns_zone_partner_id, null)
  maintenance_configuration_name = try(var.config.maintenance_configuration_name, "SQL_Default")
  minimum_tls_version            = try(var.config.minimum_tls_version, "1.2")
  proxy_override                 = try(var.config.proxy_override, "Default")
  public_data_endpoint_enabled   = try(var.config.public_data_endpoint_enabled, false)
  service_principal_type         = try(var.config.service_principal_type, null) == "SystemAssigned" ? "SystemAssigned" : null
  storage_account_type           = try(var.config.storage_account_type, "GRS")
  zone_redundant_enabled         = try(var.config.zone_redundant_enabled, false)
  timezone_id                    = try(var.config.timezone_id, "UTC")


  dynamic "identity" {
    for_each = try(var.config.identity, null) != null ? { "default" = var.config.identity } : {}

    content {
      type = identity.value.type
      identity_ids = try(
        identity.value.identity_ids, [],
      )
    }
  }

  tags = try(
    var.config.tags, var.tags, {}
  )
}

# databases
resource "azurerm_mssql_managed_database" "databases" {
  for_each = lookup(
    var.config, "databases", {}
  )

  name                      = each.value.name
  managed_instance_id       = azurerm_mssql_managed_instance.sql.id
  short_term_retention_days = try(each.value.short_term_retention_days, 7)

  dynamic "long_term_retention_policy" {
    for_each = lookup(var.config, "long_term_retention_policy", null) != null ? { "default" = var.config.long_term_retention_policy } : {}

    content {
      week_of_year      = try(long_term_retention_policy.value.week_of_year, null)
      weekly_retention  = try(long_term_retention_policy.value.weekly_retention, null)
      yearly_retention  = try(long_term_retention_policy.value.yearly_retention, null)
      monthly_retention = try(long_term_retention_policy.value.monthly_retention, null)
    }
  }

  dynamic "point_in_time_restore" {
    for_each = lookup(var.config, "point_in_time_restore", null) != null ? { "default" = var.config.point_in_time_restore } : {}

    content {
      source_database_id    = point_in_time_restore.value.source_database_id
      restore_point_in_time = point_in_time_restore.value.restore_point_in_time
    }
  }
}

# security alert policy
resource "azurerm_mssql_managed_instance_security_alert_policy" "policy" {
  for_each = lookup(var.config, "security_alert_policy", null) != null ? { "default" = var.config.security_alert_policy } : {}

  resource_group_name          = azurerm_mssql_managed_instance.sql.resource_group_name
  managed_instance_name        = azurerm_mssql_managed_instance.sql.name
  enabled                      = true
  storage_endpoint             = each.value.storage_endpoint
  storage_account_access_key   = each.value.storage_account_access_key
  retention_days               = try(each.value.retention_days, 30)
  email_account_admins_enabled = try(each.value.email_account_admins_enabled, true)
  email_addresses              = try(each.value.email_addresses, [])
  disabled_alerts              = try(each.value.disabled_alerts, [])
}

resource "azurerm_mssql_managed_instance_vulnerability_assessment" "assessment" {
  for_each = lookup(var.config, "vulnerability_assessment", null) != null ? { "default" = var.config.vulnerability_assessment } : {}

  managed_instance_id        = azurerm_mssql_managed_instance.sql.id
  storage_container_path     = each.value.storage_container_path
  storage_account_access_key = each.value.storage_account_access_key
  storage_container_sas_key  = try(each.value.storage_container_sas_key, null)

  recurring_scans {
    enabled                   = try(each.value.recurring_scans.enabled, true)
    email_subscription_admins = try(each.value.recurring_scans.email_subscription_admins, true)
    emails                    = try(each.value.recurring_scans.emails, [])
  }

  depends_on = [azurerm_mssql_managed_instance_security_alert_policy.policy]
}

data "azurerm_client_config" "current" {
}

data "azuread_service_principal" "current" {
  for_each = try(var.config.ad_admin.principal_type, null) == "ServicePrincipal" ? { "id" = {} } : {}

  object_id = try(var.config.ad_admin.object_id, null) != null ? var.config.ad_admin.object_id : try(
  var.config.ad_admin.display_name, null) == null ? data.azurerm_client_config.current.object_id : null

  display_name = try(var.config.ad_admin.display_name, null)
}

data "azuread_user" "current" {
  for_each = try(var.config.ad_admin.principal_type, null) == "User" ? { "id" = {} } : {}

  object_id = try(var.config.ad_admin.object_id, null) != null ? var.config.ad_admin.object_id : try(
  var.config.ad_admin.user_principal_name, null) == null ? data.azurerm_client_config.current.object_id : null

  user_principal_name = try(var.config.ad_admin.user_principal_name, null)
}

data "azuread_group" "current" {
  for_each = try(var.config.ad_admin.principal_type, null) == "Group" ? { "id" = {} } : {}

  object_id    = try(var.config.ad_admin.object_id, null)
  display_name = try(var.config.ad_admin.display_name, null)
}


resource "azurerm_mssql_managed_instance_active_directory_administrator" "sql" {
  for_each = try(var.config.ad_admin, null) != null ? { "ad_admin" = {} } : {}

  managed_instance_id         = azurerm_mssql_managed_instance.sql.id
  tenant_id                   = try(var.config.ad_admin.tenant_id, data.azurerm_client_config.current.tenant_id)
  azuread_authentication_only = try(var.config.ad_admin.azuread_authentication_only, false)

  login_username = var.config.ad_admin.principal_type == "User" ? data.azuread_user.current[
  "id"].user_principal_name : var.config.ad_admin.principal_type == "Group" ? data.azuread_group.current["id"].display_name : data.azuread_service_principal.current["id"].display_name
  object_id = var.config.ad_admin.principal_type == "User" ? data.azuread_user.current[
  "id"].object_id : var.config.ad_admin.principal_type == "Group" ? data.azuread_group.current["id"].object_id : data.azuread_service_principal.current["id"].object_id

  depends_on = [time_sleep.wait_after_directory_role_assignment]
}

## In order to set an Active Directory Admin, you need to assign the Directory Readers role to the system assigned managed identity of the SQL Managed Instance.
resource "azuread_directory_role" "reader" {
  for_each     = try(var.config.ad_admin, null) != null ? { "ad_admin" = {} } : {}
  display_name = "Directory Readers"
}

resource "azuread_directory_role_assignment" "role" {
  for_each = try(var.config.ad_admin, null) != null ? { "ad_admin" = {} } : {}

  role_id             = azuread_directory_role.reader["ad_admin"].template_id
  principal_object_id = azurerm_mssql_managed_instance.sql.identity[0].principal_id
}

resource "time_sleep" "wait_after_directory_role_assignment" {
  for_each = try(var.config.ad_admin, null) != null ? { "ad_admin" = {} } : {}

  depends_on      = [azuread_directory_role_assignment.role]
  create_duration = "10s"
}
