# Databases

This deploys databases on a sql manahed instance.

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
  databases                     = optional(map(object({
    name                        = optional(string)
    short_term_retention_days   = optional(number)
    long_term_retention_policy  = optional(object({
      weekly_retention          = optional(string)
      monthly_retention         = optional(string)
      yearly_retention          = optional(string)
      week_of_year              = optional(number)
    }))
  })))
})
