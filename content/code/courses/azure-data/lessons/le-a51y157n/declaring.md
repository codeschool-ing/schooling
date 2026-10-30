---
title: Declaring the workspace and the pool
version: 1
---

@@DC-INTRO@@

```sh
mkdir -p ~/azure/tf/synapse && cd ~/azure/tf/synapse
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

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_storage_account" "lake" {
  name                     = "stquitandalakeprd"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "lake" {
  name               = "lake"
  storage_account_id = azurerm_storage_account.lake.id
}

resource "azurerm_synapse_workspace" "analytics" {
  name                                 = "synw-quitanda-prd"
  resource_group_name                  = azurerm_resource_group.data.name
  location                             = azurerm_resource_group.data.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.lake.id
  sql_administrator_login              = "quitanda-admin"
  sql_administrator_login_password     = var.sql_admin_password

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_sql_pool" "warehouse" {
  name                 = "dw_quitanda"
  synapse_workspace_id = azurerm_synapse_workspace.analytics.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  storage_account_type = "LRS"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}
```

```
@@TF@@
```

@@TF-TEXT@@
