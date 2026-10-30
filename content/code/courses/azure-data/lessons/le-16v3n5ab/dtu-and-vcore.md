---
title: DTU and vCore, the two ways to buy one
version: 1
---

**A database on Azure SQL Database is bought by its compute, and there are two ways to say how much.**
The DTU model sells a bundle: a number of database transaction units, each one a fixed blend of
processor, memory and IO, with the storage included up to a size. The vCore model sells the parts:
a number of virtual cores on a named generation of hardware, the storage priced apart, and a choice of
how the database is built underneath. The engine is the same in both. What differs is what you are
allowed to choose, and what the bill counts.

**This section is taught from Microsoft's documentation, and nothing in it was run against Azure.**
The declarations at the end are checked by Terraform, offline, which is real output about the
provider's rules and nothing more.

## DTU: three tiers, one number

| tier | sizes | what it is for |
|---|---|---|
| Basic | 5 DTUs | a small database with light, occasional use |
| Standard | S0 is 10 DTUs, S1 20, S2 50, S3 100, and on up to S12 | most workloads that do not need fast IO |
| Premium | P1 is 125 DTUs, and on up to P15 | IO-heavy work, on local solid-state storage |

**A DTU cannot be read off a machine**: it is Microsoft's measure of a mixed benchmark, and the only
way to learn how many a database needs is to run it and watch the percentage it uses. That is its
strength for a small team, since one number moves everything together, and its weakness for anybody
who knows that the database needs memory and not processor: in the DTU model the two cannot be bought
apart.

## vCore: three tiers, built differently

| tier | how it is built | what it buys |
|---|---|---|
| General Purpose | compute on one node, the data on remote premium storage | the default; a failover starts a new node and attaches the storage |
| Business Critical | data on the node's local SSD, kept in step on further replicas | lower latency on IO, a faster failover, and a readable replica included |
| Hyperscale | compute apart from a tier of page servers that hold the data | storage that grows far past the others, quick restores, extra replicas for reading |

**The vCore model is the newer of the two, and two things exist only in it.** The first is the serverless compute of the next section. The second is the Azure Hybrid Benefit:
a company that owns SQL Server licences with Software Assurance pays for the vCores without the
licence part of the price. For a company moving out of a cupboard full of licensed SQL Servers, that
is the largest single line of the decision, and the DTU model cannot use it.

**Storage, in vCore, is billed apart**, per GB of the maximum size you set, and so are the backups
past an allowance. A month is 730 hours, as in Microsoft's own
calculator, and compute is priced per vCore per hour. At an illustrative 0.25 USD per vCore-hour, the
two vCores of a `GP_Gen5_2` cost 2 × 0.25 × 730 = 365.00 a month, with nobody connected.

## The names, as a declaration

The names you choose between are short strings: `Basic`, `S0` and `P1` for DTU, and for vCore the tier,
the hardware and the cores, `GP_Gen5_2`, `BC_Gen5_4`, `HS_Gen5_8`. Quitanda's orders database, its
logical server and a development copy, declared for Terraform. Make a directory for it:

```sh
mkdir -p ~/azure/tf/sql && cd ~/azure/tf/sql
```

and save this in it:

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

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_mssql_server" "orders" {
  name                         = "sql-quitanda-orders-prd"
  resource_group_name          = azurerm_resource_group.data.name
  location                     = azurerm_resource_group.data.location
  version                      = "12.0"
  administrator_login          = "quitanda"
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "orders" {
  name        = "orders"
  server_id   = azurerm_mssql_server.orders.id
  sku_name    = "GP_Gen5_2"
  max_size_gb = 100

  short_term_retention_policy {
    retention_days = 7
  }
}

resource "azurerm_mssql_database" "orders_dev" {
  name                        = "orders-dev"
  server_id                   = azurerm_mssql_server.orders.id
  sku_name                    = "GP_S_Gen5_2"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 32
}
```

**The password is a variable marked sensitive, and it has no value in the file**, so it never lands in
a repository; a real deployment passes it in from a secret store. `version = "12.0"` is the API
version of the logical server, which has been `12.0` for years and says nothing about the engine.
`retention_days` is the point-in-time window of the first section.

```
ana@laptop:~/azure/tf/sql$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/sql$ terraform validate -no-color
Success! The configuration is valid.

```

The provider knows the shape of a name, if not every name Azure sells:

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/"GP_Gen5_2"/"GP-Gen5-2"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf

Error: invalid value for sku_name (This is not a valid sku name. For example, a valid sku name is 'GP_S_Gen5_1','HS_Gen4_1','BC_Gen5_2', 'ElasticPool', 'Basic', 'S0', 'P1'.)

  with azurerm_mssql_database.orders,
  on main.tf line 37, in resource "azurerm_mssql_database" "orders":
  37:   sku_name    = "GP-Gen5-2"

```

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/retention_days = 7/retention_days = 40/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected short_term_retention_policy.0.retention_days to be in the range (1 - 35), got 40
```

**Both refusals are the provider's own rules, checked with no account**: a name that does not have
the shape of a SKU, and a retention outside the 1 to 35 days the documentation gives. What
`validate` cannot know is whether `brazilsouth` sells a given size today, or whether your
subscription's quota allows it; that is answered only by Azure, at creation.
