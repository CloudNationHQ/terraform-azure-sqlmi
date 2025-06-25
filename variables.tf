variable "config" {
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
    administrator_login            = optional(string, "adminLogin")
    collation                      = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    dns_zone_partner_id            = optional(string)
    maintenance_configuration_name = optional(string, "SQL_Default")
    minimum_tls_version            = optional(string, "1.2")
    proxy_override                 = optional(string, "Default")
    public_data_endpoint_enabled   = optional(bool, false)
    service_principal_type         = optional(string)
    storage_account_type           = optional(string, "GRS")
    zone_redundant_enabled         = optional(bool, false)
    timezone_id                    = optional(string, "UTC")
    tags                           = optional(map(string))
    identity = optional(object({
      type         = string
      identity_ids = optional(list(string), [])
    }))
    databases = optional(map(object({
      name                      = string
      short_term_retention_days = optional(number, 7)
      long_term_retention_policy = optional(object({
        week_of_year      = optional(number)
        weekly_retention  = optional(string)
        yearly_retention  = optional(string)
        monthly_retention = optional(string)
      }))
      point_in_time_restore = optional(object({
        source_database_id    = string
        restore_point_in_time = string
      }))
    })), {})
    security_alert_policy = optional(object({
      enabled                      = optional(bool, true)
      storage_endpoint             = string
      storage_account_access_key   = string
      retention_days               = optional(number, 30)
      email_account_admins_enabled = optional(bool, true)
      email_addresses              = optional(list(string), [])
      disabled_alerts              = optional(list(string), [])
    }))
    vulnerability_assessment = optional(object({
      storage_container_path     = string
      storage_account_access_key = string
      storage_container_sas_key  = optional(string)
      recurring_scans = optional(object({
        enabled                   = optional(bool, true)
        email_subscription_admins = optional(bool, true)
        emails                    = optional(list(string), [])
        }), {
        enabled                   = true
        email_subscription_admins = true
        emails                    = []
      })
    }))
    ad_admin = optional(object({
      principal_type              = string # "User", "Group", or "ServicePrincipal"
      tenant_id                   = optional(string)
      azuread_authentication_only = optional(bool, false)
      object_id                   = optional(string)
      display_name                = optional(string)
      user_principal_name         = optional(string) # For User type
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
}

variable "tags" {
  description = "tags to be added to the resources"
  type        = map(string)
  default     = {}
}
