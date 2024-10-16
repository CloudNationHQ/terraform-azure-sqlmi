# Security Policy

This examples illustrates a security alert policy and vulerability assesment.

## Types

```hcl
config = object({
  name                          = string
  location                      = string
  resource_group                = string
  sku_name                      = string
  storage_size_in_gb            = number
  vcores                        = number
  subnet_id                     = string
  administrator_login_password  = string
  security_alert_policy         = optional(object({
    storage_endpoint             = optional(string)
    storage_account_access_key   = optional(string)
    retention_days               = optional(number)
    email_account_admins_enabled = optional(bool)
    email_addresses              = optional(list(string))
    disabled_alerts              = optional(list(string))
  }))
  vulnerability_assessment      = optional(object({
    storage_container_path       = string
    storage_account_access_key   = optional(string)
    recurring_scans              = optional(object({
      enabled                    = optional(bool)
      email_subscription_admins  = optional(bool)
      emails                     = optional(list(string))
    }))
  }))
})
```
