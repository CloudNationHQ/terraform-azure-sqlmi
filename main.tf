# managed instance
resource "azurerm_mssql_managed_instance" "sql" {
  resource_group_name = coalesce(
    lookup(
      var.config, "resource_group_name", null
    ), var.resource_group_name
  )

  location = coalesce(
    lookup(var.config, "location", null
    ), var.location
  )

  name                           = var.config.name
  sku_name                       = var.config.sku_name
  license_type                   = var.config.license_type
  administrator_login            = var.config.administrator_login
  administrator_login_password   = var.config.administrator_login_password
  storage_size_in_gb             = var.config.storage_size_in_gb
  subnet_id                      = var.config.subnet_id
  vcores                         = var.config.vcores
  collation                      = var.config.collation
  dns_zone_partner_id            = var.config.dns_zone_partner_id
  maintenance_configuration_name = var.config.maintenance_configuration_name
  minimum_tls_version            = var.config.minimum_tls_version
  proxy_override                 = var.config.proxy_override
  public_data_endpoint_enabled   = var.config.public_data_endpoint_enabled
  storage_account_type           = var.config.storage_account_type
  zone_redundant_enabled         = var.config.zone_redundant_enabled
  timezone_id                    = var.config.timezone_id
  service_principal_type         = try(var.config.service_principal_type, null) == "SystemAssigned" ? "SystemAssigned" : null

  dynamic "identity" {
    for_each = lookup(var.config, "identity", null) != null ? [var.config.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  tags = coalesce(
    var.config.tags, var.tags
  )
}

# databases
resource "azurerm_mssql_managed_database" "databases" {
  for_each = lookup(
    var.config, "databases", {}
  )

  name                      = each.value.name
  managed_instance_id       = azurerm_mssql_managed_instance.sql.id
  short_term_retention_days = each.value.short_term_retention_days

  dynamic "long_term_retention_policy" {
    for_each = try(each.value.long_term_retention_policy, null) != null ? { "default" = each.value.long_term_retention_policy } : {}

    content {
      week_of_year      = long_term_retention_policy.value.week_of_year
      weekly_retention  = long_term_retention_policy.value.weekly_retention
      yearly_retention  = long_term_retention_policy.value.yearly_retention
      monthly_retention = long_term_retention_policy.value.monthly_retention
    }
  }

  dynamic "point_in_time_restore" {
    for_each = try(each.value.point_in_time_restore, null) != null ? { "default" = each.value.point_in_time_restore } : {}

    content {
      source_database_id    = point_in_time_restore.value.source_database_id
      restore_point_in_time = point_in_time_restore.value.restore_point_in_time
    }
  }
}

# security alert policy
resource "azurerm_mssql_managed_instance_security_alert_policy" "policy" {
  for_each = nonsensitive(lookup(var.config, "security_alert_policy", null) != null ? { "default" = var.config.security_alert_policy } : {})

  resource_group_name = coalesce(
    lookup(
      var.config, "resource_group_name", null
    ), var.resource_group_name
  )

  managed_instance_name        = azurerm_mssql_managed_instance.sql.name
  enabled                      = each.value.enabled
  storage_endpoint             = each.value.storage_endpoint
  storage_account_access_key   = each.value.storage_account_access_key
  retention_days               = each.value.retention_days
  email_account_admins_enabled = each.value.email_account_admins_enabled
  email_addresses              = each.value.email_addresses
  disabled_alerts              = each.value.disabled_alerts
}

# vulnerability assessment
resource "azurerm_mssql_managed_instance_vulnerability_assessment" "assessment" {
  for_each = nonsensitive(lookup(var.config, "vulnerability_assessment", null) != null ? { "default" = var.config.vulnerability_assessment } : {})

  managed_instance_id        = azurerm_mssql_managed_instance.sql.id
  storage_container_path     = each.value.storage_container_path
  storage_account_access_key = each.value.storage_account_access_key
  storage_container_sas_key  = each.value.storage_container_sas_key

  recurring_scans {
    enabled                   = each.value.recurring_scans.enabled
    email_subscription_admins = each.value.recurring_scans.email_subscription_admins
    emails                    = each.value.recurring_scans.emails
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

# active directory administrator
resource "azurerm_mssql_managed_instance_active_directory_administrator" "sql" {
  for_each = try(var.config.ad_admin, null) != null ? { "ad_admin" = {} } : {}

  managed_instance_id         = azurerm_mssql_managed_instance.sql.id
  azuread_authentication_only = var.config.ad_admin.azuread_authentication_only

  tenant_id = coalesce(
    var.config.ad_admin.tenant_id, data.azurerm_client_config.current.tenant_id
  )

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
