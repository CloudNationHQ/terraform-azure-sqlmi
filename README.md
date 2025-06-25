# Sql Managed Instance

This terraform module streamlines the deployment and configuration of azure sql managed instances, offering customizable settings for databases, security policies, and vulnerability assessments.

## Features

Support for multiple database configurations.

Utilization of terratest for robust validation.

Integration of vulnerability assessment capabilities.

Security alert policy support with customizable alert types and email notifications.

<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.0)

- <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) (~> 3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_time"></a> [time](#requirement\_time) (~> 0.12)

## Providers

The following providers are used by this module:

- <a name="provider_azuread"></a> [azuread](#provider\_azuread) (~> 3.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 4.0)

- <a name="provider_time"></a> [time](#provider\_time) (~> 0.12)

## Resources

The following resources are used by this module:

- [azuread_directory_role.reader](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/directory_role) (resource)
- [azuread_directory_role_assignment.role](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/directory_role_assignment) (resource)
- [azurerm_mssql_managed_database.databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_database) (resource)
- [azurerm_mssql_managed_instance.sql](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance) (resource)
- [azurerm_mssql_managed_instance_active_directory_administrator.sql](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance_active_directory_administrator) (resource)
- [azurerm_mssql_managed_instance_security_alert_policy.policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance_security_alert_policy) (resource)
- [azurerm_mssql_managed_instance_vulnerability_assessment.assessment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/mssql_managed_instance_vulnerability_assessment) (resource)
- [time_sleep.wait_after_directory_role_assignment](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) (resource)
- [azuread_group.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group) (data source)
- [azuread_service_principal.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) (data source)
- [azuread_user.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/user) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

## Required Inputs

The following input variables are required:

### <a name="input_config"></a> [config](#input\_config)

Description: Contains all sql managed instance configuration

Type:

```hcl
object({
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
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_location"></a> [location](#input\_location)

Description: default azure region to be used.

Type: `string`

Default: `null`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: default resource group to be used.

Type: `string`

Default: `null`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: tags to be added to the resources

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_config"></a> [config](#output\_config)

Description: Contains all sql managed instance configuration

### <a name="output_databases"></a> [databases](#output\_databases)

Description: Contains all sql managed instance databases
<!-- END_TF_DOCS -->

## Goals

For more information, please see our [goals and non-goals](./GOALS.md).

## Testing

For more information, please see our testing [guidelines](./TESTING.md)

## Notes

Using a dedicated module, we've developed a naming convention for resources that's based on specific regular expressions for each type, ensuring correct abbreviations and offering flexibility with multiple prefixes and suffixes.

Full examples detailing all usages, along with integrations with dependency modules, are located in the examples directory.

To update the module's documentation run `make doc`

## Contributors

We welcome contributions from the community! Whether it's reporting a bug, suggesting a new feature, or submitting a pull request, your input is highly valued.

For more information, please see our contribution [guidelines](./CONTRIBUTING.md). <br><br>

<a href="https://github.com/cloudnationhq/terraform-azure-sqlmi/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=cloudnationhq/terraform-azure-sqlmi" />
</a>

## License

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## References

- [Documentation](https://learn.microsoft.com/en-us/azure/azure-sql/managed-instance/)
- [Rest Api](https://learn.microsoft.com/en-us/rest/api/sql/managed-instances)
- [Rest Api Specs](https://github.com/hashicorp/pandora/tree/main/api-definitions/resource-manager/Sql/2023-08-01-preview/ManagedInstances)
