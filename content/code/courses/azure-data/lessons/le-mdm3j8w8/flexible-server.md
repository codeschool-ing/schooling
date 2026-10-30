---
title: A flexible server, and the three sizes of machine
version: 1
---

**Azure Database for PostgreSQL and Azure Database for MySQL are each sold as a flexible server**: a
real server running the open-source engine, in the major version you choose, on a machine size you
choose, with Microsoft doing the patching, the backups and the failover. It is closer to a server in a
cupboard than lesson 8's logical server is. There is one engine and one machine, you pick the version,
and the database's name is yours to create inside it. The older deployment option, Single Server,
has been retired, so flexible server is what this lesson means by either.

**This section is taught from Microsoft's documentation, and nothing in it was run against Azure.**
The declaration is checked by Terraform, offline; the next two run the engine itself.

## The three compute tiers

| tier | machine family | what it is for |
|---|---|---|
| Burstable | B-series, for example `B_Standard_B1ms` | development, tests, a small site: cheap, with processor credits it spends in bursts |
| General Purpose | D-series, for example `GP_Standard_D2ds_v5` | most production databases: a balance of processor and memory |
| Memory Optimized | E-series, for example `MO_Standard_E4ds_v5` | large working sets, where more memory per vCore keeps the hot data cached |

**The names are the tier, then the machine size Azure sells as a virtual machine**, which is the
plainest difference from Azure SQL Database: here you are buying a VM-sized server with a database
engine on it, and its bill is the VM's hours plus the storage. Burstable is the cheapest and comes with
limits the documentation lists, and this lesson meets two of them: no high availability, and no
built-in PgBouncer.

**Storage is provisioned and can grow but not shrink.** You choose a size, the server's disk is that
size from the first day and billed as such, and autogrow can raise it as the data approaches the
limit. Making it smaller again means a new server and a copy. So the size is chosen for next year, not
for the size of the dump.

**A server can be stopped**, which stops the compute bill while storage continues, for up to seven
days; the documentation says Azure starts it again after that. It is for a development server that
nobody uses at the weekend, not for a production one.

## The declaration

Quitanda's orders could have lived on PostgreSQL instead, and the declaration of that choice is short.
In a new directory:

```sh
mkdir -p ~/azure/tf/flex && cd ~/azure/tf/flex
```

`main.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "db_admin_password" {
  type      = string
  sensitive = true
}

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_postgresql_flexible_server" "orders" {
  name                          = "psql-quitanda-orders-prd"
  resource_group_name           = azurerm_resource_group.data.name
  location                      = azurerm_resource_group.data.location
  version                       = "17"
  sku_name                      = "GP_Standard_D2ds_v5"
  storage_mb                    = 131072
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  zone                          = "1"
  administrator_login           = "quitanda"
  administrator_password        = var.db_admin_password
  public_network_access_enabled = false

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
}
```

`version = "17"` is the major version, the same as the container this lesson runs. `storage_mb` is
128 GB, written in MB because that is the unit the API takes. The `high_availability` block is the
subject of a later section of this lesson.

```
ana@laptop:~/azure/tf/flex$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/flex$ terraform validate -no-color
Success! The configuration is valid.

```

```
ana@laptop:~/azure/tf/flex$ sed -i.bak 's/"GP_Standard_D2ds_v5"/"Standard_D2ds_v5"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf

Error: invalid value for sku_name (is not a valid sku name)

  with azurerm_postgresql_flexible_server.orders,
  on main.tf line 29, in resource "azurerm_postgresql_flexible_server" "orders":
  29:   sku_name                      = "Standard_D2ds_v5"

```

**A size has to carry its tier in front**, `GP_` here, and the provider refuses the bare machine name.
It says less than lesson 8's message did: not which names exist, only that this one is not one.
