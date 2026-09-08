variable "mssql_managed_instance" {
  description = "Contains all sql managed instance configuration"
  type = object({
    name                           = string
    sku_name                       = string
    administrator_login_password   = string
    storage_size_in_gb             = number
    subnet_id                      = string
    vcores                         = number
    resource_group_name            = optional(string)
    location                       = optional(string)
    license_type                   = optional(string, "LicenseIncluded")
    administrator_login            = optional(string)
    collation                      = optional(string)
    database_format                = optional(string)
    dns_zone_partner_id            = optional(string)
    hybrid_secondary_usage         = optional(string)
    maintenance_configuration_name = optional(string)
    minimum_tls_version            = optional(string)
    proxy_override                 = optional(string)
    public_data_endpoint_enabled   = optional(bool)
    service_principal_type         = optional(string)
    storage_account_type           = optional(string)
    zone_redundant_enabled         = optional(bool)
    timezone_id                    = optional(string)
    general_purpose_v2_enabled     = optional(bool)
    storage_iops                   = optional(number)
    tags                           = optional(map(string))
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    azure_active_directory_administrator = optional(object({
      login_username                      = string
      object_id                           = string
      principal_type                      = string
      azuread_authentication_only_enabled = optional(bool, false)
      tenant_id                           = optional(string)
    }))
    databases = optional(map(object({
      name                      = string
      short_term_retention_days = optional(number, 7)
      tags                      = optional(map(string))
      long_term_retention_policy = optional(object({
        weekly_retention  = optional(string)
        monthly_retention = optional(string)
        yearly_retention  = optional(string)
        week_of_year      = optional(number)
      }))
      point_in_time_restore = optional(object({
        source_database_id    = string
        restore_point_in_time = string
      }))
    })), {})
    security_alert_policy = optional(object({
      enabled                      = optional(bool)
      storage_endpoint             = optional(string)
      storage_account_access_key   = optional(string)
      retention_days               = optional(number)
      email_account_admins_enabled = optional(bool)
      email_addresses              = optional(list(string), [])
      disabled_alerts              = optional(list(string), [])
    }))
    vulnerability_assessment = optional(object({
      storage_container_path     = string
      storage_account_access_key = optional(string)
      storage_container_sas_key  = optional(string)
      recurring_scans = optional(object({
        enabled                   = optional(bool)
        email_subscription_admins = optional(bool)
        emails                    = optional(list(string), [])
        }), {
        enabled                   = true
        email_subscription_admins = true
        emails                    = []
      })
    }))
    ad_admin = optional(object({
      principal_type              = string
      tenant_id                   = optional(string)
      azuread_authentication_only = optional(bool, false)
      object_id                   = optional(string)
      display_name                = optional(string)
      client_id                   = optional(string)
      user_principal_name         = optional(string)
      mail                        = optional(string)
      employee_id                 = optional(string)
      mail_nickname               = optional(string)
      mail_enabled                = optional(bool)
      security_enabled            = optional(bool)
      include_transitive_members  = optional(bool)
      directory_role = optional(object({
        display_name = optional(string, "Directory Readers")
        template_id  = optional(string)
      }), {})
      directory_role_assignment = optional(object({
        app_scope_id       = optional(string)
        directory_scope_id = optional(string)
      }), {})
      time_sleep = optional(object({
        create_duration  = optional(string, "10s")
        destroy_duration = optional(string)
        triggers         = optional(map(string))
      }), {})
    }))
  })
}

variable "location" {
  description = "default azure region to be used."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "default resource group to be used."
  type        = string
  default     = null

  validation {
    condition     = var.resource_group_name == null || can(regex("^[a-zA-Z0-9_.()-]{1,90}$", var.resource_group_name))
    error_message = "Resource group name must be 1-90 characters and can only include alphanumeric characters, underscores, parentheses, hyphens, and periods."
  }
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = map(string)
  default     = {}
}
