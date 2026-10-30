---
title: Inside your network, in a subnet of its own
version: 1
---

**A Managed Instance lives inside your virtual network**, in a subnet given over to it, and answers on a
private address there. Azure SQL Database starts on the internet and is pulled inside with a private
endpoint; Managed Instance starts inside and is let out, if at all, by a public endpoint you switch on.
For a company whose security team asks first where the database answers, that is often the deciding
line.

**This section is taught from Microsoft's documentation, and nothing in it was run against Azure.**
The declaration is checked by Terraform, offline.

## The subnet, and what lives in it

**The subnet is delegated to `Microsoft.Sql/managedInstances`**, which hands it to the service: Azure
places the instance's machines there, and attaches the routes and the network security rules the
service needs to manage them. Nothing else may be put in that subnet. One subnet can hold several
instances, and the documentation sizes it by how many and how large, so it is chosen with room to grow;
a subnet too small for the next instance is a migration to another subnet.

**Creating or resizing an instance is a long-running operation**, because Azure builds the group of
machines that host it, the virtual cluster, inside your subnet before the instance answers. The
documentation gives the expected duration of each kind of operation, and a plan that resizes the
instance during the working day has to read it first.

**The public endpoint is off unless you turn it on.** When it is on, it answers on port 3342, not 1433,
and only the network rules you write let anybody reach it. Leaving it off, and reaching the instance
from inside the network or over a VPN, is the arrangement `azure-foundations` lessons 16 and 23
describe for any private service.

## The declaration

A virtual network, a delegated subnet and an instance. In a new directory:

```sh
mkdir -p ~/azure/tf/sqlmi && cd ~/azure/tf/sqlmi
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

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_virtual_network" "data" {
  name                = "vnet-quitanda-data-prd"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "mi" {
  name                 = "snet-sqlmi"
  resource_group_name  = azurerm_resource_group.data.name
  virtual_network_name = azurerm_virtual_network.data.name
  address_prefixes     = ["10.20.1.0/24"]

  delegation {
    name = "sqlmi"
    service_delegation {
      name = "Microsoft.Sql/managedInstances"
    }
  }
}

resource "azurerm_mssql_managed_instance" "orders" {
  name                         = "sqlmi-quitanda-prd"
  resource_group_name          = azurerm_resource_group.data.name
  location                     = azurerm_resource_group.data.location
  subnet_id                    = azurerm_subnet.mi.id
  sku_name                     = "GP_Gen5"
  vcores                       = 8
  storage_size_in_gb           = 256
  license_type                 = "BasePrice"
  administrator_login          = "quitanda"
  administrator_login_password = var.sql_admin_password
  public_data_endpoint_enabled = false
}
```

**The name is the tier and the hardware, and the vCores are a separate number**, unlike lesson 8's
`GP_Gen5_2`. `storage_size_in_gb` is bought apart from the compute, as in the vCore model.
`license_type = "BasePrice"` is the Azure Hybrid Benefit, the price without the licence;
`LicenseIncluded` is the other value. And `public_data_endpoint_enabled = false` writes down the
default, so that a reviewer reading the file sees the decision.

```
ana@laptop:~/azure/tf/sqlmi$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/sqlmi$ terraform validate -no-color
Success! The configuration is valid.

```

Write lesson 8's name here and the provider says what it expects instead:

```
ana@laptop:~/azure/tf/sqlmi$ sed -i.bak 's/"GP_Gen5"/"GP_Gen5_8"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf

Error: expected sku_name to be one of ["BC_Gen4" "BC_Gen5" "BC_Gen8IH" "BC_Gen8IM" "GP_Gen4" "GP_Gen5" "GP_Gen8IH" "GP_Gen8IM"], got GP_Gen5_8

  with azurerm_mssql_managed_instance.orders,
  on main.tf line 50, in resource "azurerm_mssql_managed_instance" "orders":
  50:   sku_name                     = "GP_Gen5_8"

```

```
ana@laptop:~/azure/tf/sqlmi$ sed -i.bak 's/"BasePrice"/"BringYourOwn"/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected license_type to be one of ["LicenseIncluded" "BasePrice"], got BringYourOwn
```

**`GP_Gen5_8` is a valid name for a database and an invalid one for an instance**, and the provider's
list says why: an instance names its tier and hardware only. The licence list has two values, and the
Hybrid Benefit is the one called `BasePrice`, a name nobody would guess from the marketing.
