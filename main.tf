# managed instance
resource "azurerm_mssql_managed_instance" "this" {
  resource_group_name = coalesce(
    var.mssql_managed_instance.resource_group_name, var.resource_group_name
  )

  location = coalesce(
    var.mssql_managed_instance.location, var.location
  )

  name                           = var.mssql_managed_instance.name
  sku_name                       = var.mssql_managed_instance.sku_name
  license_type                   = var.mssql_managed_instance.license_type
  administrator_login            = var.mssql_managed_instance.administrator_login
  administrator_login_password   = var.mssql_managed_instance.administrator_login_password
  storage_size_in_gb             = var.mssql_managed_instance.storage_size_in_gb
  subnet_id                      = var.mssql_managed_instance.subnet_id
  vcores                         = var.mssql_managed_instance.vcores
  collation                      = var.mssql_managed_instance.collation
  database_format                = var.mssql_managed_instance.database_format
  dns_zone_partner_id            = var.mssql_managed_instance.dns_zone_partner_id
  hybrid_secondary_usage         = var.mssql_managed_instance.hybrid_secondary_usage
  maintenance_configuration_name = var.mssql_managed_instance.maintenance_configuration_name
  minimum_tls_version            = var.mssql_managed_instance.minimum_tls_version
  proxy_override                 = var.mssql_managed_instance.proxy_override
  public_data_endpoint_enabled   = var.mssql_managed_instance.public_data_endpoint_enabled
  storage_account_type           = var.mssql_managed_instance.storage_account_type
  zone_redundant_enabled         = var.mssql_managed_instance.zone_redundant_enabled
  timezone_id                    = var.mssql_managed_instance.timezone_id
  service_principal_type         = var.mssql_managed_instance.service_principal_type
  general_purpose_v2_enabled     = var.mssql_managed_instance.general_purpose_v2_enabled
  storage_iops                   = var.mssql_managed_instance.storage_iops

  dynamic "identity" {
    for_each = var.mssql_managed_instance.identity != null ? { "this" = var.mssql_managed_instance.identity } : {}

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "azure_active_directory_administrator" {
    for_each = var.mssql_managed_instance.azure_active_directory_administrator != null ? { "this" = var.mssql_managed_instance.azure_active_directory_administrator } : {}

    content {
      login_username                      = azure_active_directory_administrator.value.login_username
      object_id                           = azure_active_directory_administrator.value.object_id
      principal_type                      = azure_active_directory_administrator.value.principal_type
      azuread_authentication_only_enabled = azure_active_directory_administrator.value.azuread_authentication_only_enabled
      tenant_id                           = azure_active_directory_administrator.value.tenant_id
    }
  }

  tags = coalesce(
    var.mssql_managed_instance.tags, var.tags
  )
}

# databases
resource "azurerm_mssql_managed_database" "this" {
  for_each = var.mssql_managed_instance.databases

  name                      = each.value.name
  managed_instance_id       = azurerm_mssql_managed_instance.this.id
  short_term_retention_days = each.value.short_term_retention_days


  dynamic "long_term_retention_policy" {
    for_each = each.value.long_term_retention_policy != null ? { "this" = each.value.long_term_retention_policy } : {}

    content {
      weekly_retention  = long_term_retention_policy.value.weekly_retention
      monthly_retention = long_term_retention_policy.value.monthly_retention
      yearly_retention  = long_term_retention_policy.value.yearly_retention
      week_of_year      = long_term_retention_policy.value.week_of_year
    }
  }

  dynamic "point_in_time_restore" {
    for_each = each.value.point_in_time_restore != null ? { "this" = each.value.point_in_time_restore } : {}

    content {
      source_database_id    = point_in_time_restore.value.source_database_id
      restore_point_in_time = point_in_time_restore.value.restore_point_in_time
    }
  }

  tags = coalesce(
    each.value.tags, var.mssql_managed_instance.tags, var.tags
  )
}

# security alert policy
resource "azurerm_mssql_managed_instance_security_alert_policy" "this" {
  for_each = nonsensitive(var.mssql_managed_instance.security_alert_policy != null ? { "this" = var.mssql_managed_instance.security_alert_policy } : {})

  resource_group_name = coalesce(
    var.mssql_managed_instance.resource_group_name, var.resource_group_name
  )

  managed_instance_name        = azurerm_mssql_managed_instance.this.name
  enabled                      = each.value.enabled
  storage_endpoint             = each.value.storage_endpoint
  storage_account_access_key   = each.value.storage_account_access_key
  retention_days               = each.value.retention_days
  email_account_admins_enabled = each.value.email_account_admins_enabled
  email_addresses              = each.value.email_addresses
  disabled_alerts              = each.value.disabled_alerts
}

# vulnerability assessment
resource "azurerm_mssql_managed_instance_vulnerability_assessment" "this" {
  for_each = nonsensitive(var.mssql_managed_instance.vulnerability_assessment != null ? { "this" = var.mssql_managed_instance.vulnerability_assessment } : {})

  managed_instance_id        = azurerm_mssql_managed_instance.this.id
  storage_container_path     = each.value.storage_container_path
  storage_account_access_key = each.value.storage_account_access_key
  storage_container_sas_key  = each.value.storage_container_sas_key

  recurring_scans {
    enabled                   = each.value.recurring_scans.enabled
    email_subscription_admins = each.value.recurring_scans.email_subscription_admins
    emails                    = each.value.recurring_scans.emails
  }

  depends_on = [azurerm_mssql_managed_instance_security_alert_policy.this]
}

data "azurerm_client_config" "this" {
}

data "azuread_service_principal" "this" {
  for_each = var.mssql_managed_instance.ad_admin != null ? var.mssql_managed_instance.ad_admin.principal_type == "ServicePrincipal" ? { "this" = var.mssql_managed_instance.ad_admin } : {} : {}

  display_name = each.value.display_name
  client_id    = each.value.client_id

  object_id = length(compact([each.value.display_name, each.value.client_id])) == 0 ? coalesce(
    each.value.object_id, data.azurerm_client_config.this.object_id
  ) : each.value.object_id
}

data "azuread_user" "this" {
  for_each = var.mssql_managed_instance.ad_admin != null ? var.mssql_managed_instance.ad_admin.principal_type == "User" ? { "this" = var.mssql_managed_instance.ad_admin } : {} : {}

  user_principal_name = each.value.user_principal_name
  mail                = each.value.mail
  mail_nickname       = each.value.mail_nickname
  employee_id         = each.value.employee_id

  object_id = length(compact([each.value.user_principal_name, each.value.mail, each.value.mail_nickname, each.value.employee_id])) == 0 ? coalesce(
    each.value.object_id, data.azurerm_client_config.this.object_id
  ) : each.value.object_id
}

data "azuread_group" "this" {
  for_each = var.mssql_managed_instance.ad_admin != null ? var.mssql_managed_instance.ad_admin.principal_type == "Group" ? { "this" = var.mssql_managed_instance.ad_admin } : {} : {}

  object_id                  = each.value.object_id
  display_name               = each.value.display_name
  mail_nickname              = each.value.mail_nickname
  mail_enabled               = each.value.mail_enabled
  security_enabled           = each.value.security_enabled
  include_transitive_members = each.value.include_transitive_members
}

# active directory administrator
resource "azurerm_mssql_managed_instance_active_directory_administrator" "this" {
  for_each = var.mssql_managed_instance.ad_admin != null ? { "this" = var.mssql_managed_instance.ad_admin } : {}

  managed_instance_id         = azurerm_mssql_managed_instance.this.id
  azuread_authentication_only = each.value.azuread_authentication_only

  tenant_id = coalesce(
    each.value.tenant_id, data.azurerm_client_config.this.tenant_id
  )

  login_username = one(concat(
    values(data.azuread_user.this)[*].user_principal_name,
    values(data.azuread_group.this)[*].display_name,
    values(data.azuread_service_principal.this)[*].display_name,
  ))

  object_id = one(concat(
    values(data.azuread_user.this)[*].object_id,
    values(data.azuread_group.this)[*].object_id,
    values(data.azuread_service_principal.this)[*].object_id,
  ))

  depends_on = [time_sleep.this]
}

resource "azuread_directory_role" "this" {
  for_each = var.mssql_managed_instance.ad_admin != null ? { "this" = var.mssql_managed_instance.ad_admin } : {}

  template_id  = each.value.directory_role.template_id
  display_name = each.value.directory_role.template_id == null ? each.value.directory_role.display_name : null
}

resource "azuread_directory_role_assignment" "this" {
  for_each = var.mssql_managed_instance.ad_admin != null ? { "this" = var.mssql_managed_instance.ad_admin } : {}

  role_id             = one(values(azuread_directory_role.this)).template_id
  principal_object_id = one(azurerm_mssql_managed_instance.this.identity).principal_id
  app_scope_id        = each.value.directory_role_assignment.app_scope_id
  directory_scope_id  = each.value.directory_role_assignment.directory_scope_id
}

resource "time_sleep" "this" {
  for_each = var.mssql_managed_instance.ad_admin != null ? { "this" = var.mssql_managed_instance.ad_admin } : {}

  create_duration  = each.value.time_sleep.create_duration
  destroy_duration = each.value.time_sleep.destroy_duration
  triggers         = each.value.time_sleep.triggers

  depends_on = [azuread_directory_role_assignment.this]
}
