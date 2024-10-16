# Default

This example illustrates the default setup, in its simplest form.

## Types

```hcl
config = object({
  name                          = string
  sku_name                      = string
  storage_size_in_gb            = number
  vcores                        = number
  subnet_id                     = string
  administrator_login_password  = string
})
```
