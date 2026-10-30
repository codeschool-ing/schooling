---
title: A workspace in your own network, declared and checked
version: 1
---

**A Databricks workspace is created by Azure Resource Manager, so its declaration can be checked the
way lesson 1 checked a storage account**: offline, by Terraform, against the provider's schema.
Nothing is created and no workspace exists afterwards. This declaration puts the workspace's
clusters in a network Quitanda owns, with no public addresses, and gives Unity Catalog an identity to
reach the lake with. Make the directory and save the file:

```sh
mkdir -p ~/azure/tf/databricks && cd ~/azure/tf/databricks
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

resource "azurerm_resource_group" "analytics" {
  name     = "rg-quitanda-analytics-prd"
  location = "brazilsouth"
}

resource "azurerm_virtual_network" "dbw" {
  name                = "vnet-quitanda-dbw-prd"
  resource_group_name = azurerm_resource_group.analytics.name
  location            = azurerm_resource_group.analytics.location
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_network_security_group" "dbw" {
  name                = "nsg-quitanda-dbw-prd"
  resource_group_name = azurerm_resource_group.analytics.name
  location            = azurerm_resource_group.analytics.location
}

resource "azurerm_subnet" "dbw" {
  for_each             = { host = "10.20.1.0/24", container = "10.20.2.0/24" }
  name                 = "snet-dbw-${each.key}"
  resource_group_name  = azurerm_resource_group.analytics.name
  virtual_network_name = azurerm_virtual_network.dbw.name
  address_prefixes     = [each.value]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "dbw" {
  for_each                  = azurerm_subnet.dbw
  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.dbw.id
}

resource "azurerm_databricks_access_connector" "unity" {
  name                = "dbac-quitanda-prd"
  resource_group_name = azurerm_resource_group.analytics.name
  location            = azurerm_resource_group.analytics.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_databricks_workspace" "dbw" {
  name                        = "dbw-quitanda-prd"
  resource_group_name         = azurerm_resource_group.analytics.name
  location                    = azurerm_resource_group.analytics.location
  sku                         = "premium"
  managed_resource_group_name = "rg-quitanda-dbw-managed-prd"

  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.dbw.id
    public_subnet_name                                   = azurerm_subnet.dbw["host"].name
    private_subnet_name                                  = azurerm_subnet.dbw["container"].name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.dbw["host"].id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.dbw["container"].id
  }
}
```

Read from the top, the file declares the network first and the workspace last, because the
workspace names everything before it:

- **one virtual network and two subnets**, `snet-dbw-host` and `snet-dbw-container`, written once with
  `for_each`. Each is **delegated** to `Microsoft.Databricks/workspaces`, which lets the workspace
  manage the network settings of the machines it puts there, and each has the same network security
  group;
- **an access connector**, `azurerm_databricks_access_connector`, which exists only to hold a
  system-assigned managed identity. Unity Catalog uses that identity to read and write the storage
  account, so no key to the lake is ever handed to Databricks; the identity still needs a role on the
  account, as lesson 19's factory did;
- **the workspace**, on the `premium` tier, with its managed resource group named rather than left to
  Azure, and `custom_parameters` that inject it into the network: the virtual network, the two subnet
  names, the two associations with the security group, and `no_public_ip = true`.

```
ana@laptop:~/azure/tf/databricks$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/databricks$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/databricks$ sed -i 's/= "premium"/= "gold"/' main.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/= "gold"/= "premium"/' main.tf
Error: expected sku to be one of ["standard" "premium" "trial"], got gold
ana@laptop:~/azure/tf/databricks$ terraform fmt -check && echo formatted
formatted
```

**The three tiers are the provider's list**, and the file is laid out as `terraform fmt` would lay it
out. What `validate` cannot know is everything Azure checks at creation: whether the two subnets are
large enough, whether the security group has the rules Databricks needs, whether the name is free.
Those fail at `apply`, against a subscription, which this course never uses.

## What a workspace does not declare

**Almost nothing that happens inside the workspace is an Azure resource.** Clusters, jobs, SQL
warehouses, notebooks, Unity Catalog's catalogues and grants all live in the control plane, and
Azure Resource Manager does not see them. They are declared with Databricks' own Terraform provider,
`databricks/databricks`, which talks to the workspace's API with a token or an Entra ID identity, and
which this course does not install: without a workspace to answer, its `validate` would check only
spelling. A team that declares its platform in Terraform therefore runs two providers, `azurerm` for
the workspace, its network and its identity, and Databricks' for everything inside, which is the same
split lesson 17 found in Fabric between the capacity and its workspaces.
