# Authentication

This section explains how to configure the Azure Active Directory (AD) administrator setup for the MSSQL Managed Instance.

* `principal_type`: specifies whether to use a **User**, **Group** or **Service Principal** for authentication.
* For **ServicePrincipal**, provide either `object_id` or `display_name` to specify a different Service Principal.
  - If neither is provided, the currently logged-in Service Principal is used.
* For **User**, `object_id` or `user_principal_name`  allow you to specify a different User. 
  - If neither is provided, the currently logged-in User is used.
* For **Group** either `object_id` or `display_name` is required. 

**Note**: You need to set identity = { type = "SystemAssigned" } in the configuration. This ensures that the SQL Managed Instance uses a system-assigned managed identity, which the module will use to configure Active Directory (AD) authentication.

The module handles the assignment of the Directory Readers role to this managed identity, which is required for AD authentication. However, for this to succeed, the Service Principal or User running Terraform must have the necessary API permissions:

If using a Service Principal, it must have the RoleManagement.ReadWrite.Directory application role.
If using a User Principal, it must be assigned one of the following directory roles: Privileged Role Administrator or Global Administrator. 

These permissions allow Terraform to assign the required Directory Readers role to the managed identity. Without these permissions, the AD administrator setup cannot be completed.

See also: [Azure AD Directory Role Assignment Documentation](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/directory_role_assignment)

## Types

```hcl
config = object({
  name                          = string
  sku_name                      = string
  storage_size_in_gb            = number
  vcores                        = number
  subnet_id                     = string
  administrator_login_password  = string

  ad_admin = optional(object({
      principal_type      = string('User', 'Group', 'ServicePrincipal')
      display_name        = optional(string)
      user_principal_name = optional(string)
      object_id           = optional(string)
    }))

    identity = optional(object({
      type          = string('UserAssigned', 'SystemAssigned')
      identity_ids  = optional(string)
    }))
})
```
