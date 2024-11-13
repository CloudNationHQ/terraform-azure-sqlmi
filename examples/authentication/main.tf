module "naming" {
  source  = "cloudnationhq/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "rg" {
  source  = "cloudnationhq/rg/azure"
  version = "~> 2.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = "uksouth"
    }
  }
}

module "network" {
  source  = "cloudnationhq/vnet/azure"
  version = "~> 8.0"

  naming = local.naming

  vnet = {
    name           = module.naming.virtual_network.name
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name
    address_space  = ["10.18.0.0/16"]

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
  version = "~> 2.0"

  naming = local.naming

  vault = {
    name           = module.naming.key_vault.name_unique
    location       = module.rg.groups.demo.location
    resource_group = module.rg.groups.demo.name

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

module "sqlmi" {
  source  = "cloudnationhq/sqlmi/azure"
  version = "~> 1.0"

  location       = module.rg.groups.demo.location
  resource_group = module.rg.groups.demo.name

  config = {
    name               = module.naming.mssql_server.name_unique
    sku_name           = "GP_Gen5"
    storage_size_in_gb = 32
    vcores             = 4

    subnet_id                    = module.network.subnets.sql.id
    administrator_login_password = module.kv.secrets.sql.value

    ad_admin = {
      principal_type = "User"
    }

    identity = {
      type = "SystemAssigned"
    }
  }
}
