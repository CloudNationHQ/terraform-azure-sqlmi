module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.24"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 2.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "westeurope"
    }
  }
}

module "network" {
  source  = "cloudnationhq/vnet/azure"
  version = "~> 9.0"

  naming = local.naming

  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.18.0.0/16"]

    subnets = {
      sql = {
        address_prefixes       = ["10.18.3.0/24"]
        network_security_group = {}
        route_table = {
          bgp_route_propagation_enabled = true
        }
        delegations = {
          managedinstance = {
            name = "Microsoft.Sql/managedInstances"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
              "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
              "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
            ]
          }
        }
      }
    }
  }
}

module "kv" {
  source  = "cloudnationhq/kv/azure"
  version = "~> 4.0"

  naming = local.naming

  vault = {
    name                = module.naming.key_vault.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    secrets = {
      random_string = {
        sql = {
          length  = 24
          special = true
        }
      }
    }
  }
}

module "storage" {
  source  = "cloudnationhq/sa/azure"
  version = "~> 4.0"

  storage = {
    name                = module.naming.storage_account.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
  }
}

module "sqlmi" {
  source  = "cloudnationhq/sqlmi/azure"
  version = "~> 2.0"

  config = {
    name                = module.naming.mssql_server.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name

    sku_name           = "GP_Gen5"
    storage_size_in_gb = 32
    vcores             = 4

    subnet_id                    = module.network.subnets.sql.id
    administrator_login_password = module.kv.secrets.sql.value

    security_alert_policy = {
      storage_endpoint             = module.storage.account.primary_blob_endpoint
      storage_account_access_key   = module.storage.account.primary_access_key
      retention_days               = 30
      email_account_admins_enabled = true
      email_addresses              = ["admin@example.com"]
      disabled_alerts              = ["Sql_Injection", "Data_Exfiltration"]
    }

    vulnerability_assessment = {
      storage_container_path     = "${module.storage.account.primary_blob_endpoint}vulnerability-assessment/"
      storage_account_access_key = module.storage.account.primary_access_key
      recurring_scans = {
        enabled                   = true
        email_subscription_admins = true
        emails                    = ["security@example.com"]
      }
    }
  }
}
