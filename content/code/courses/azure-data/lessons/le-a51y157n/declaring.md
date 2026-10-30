---
title: Declaring the workspace and the pool
version: 1
---

**The workspace, its lake and its dedicated pool are three resources, and the pool is the one that
costs money by the hour.** This section declares them for Quitanda and checks the declaration with
Terraform, which reads the file and Azure's provider and asks Azure nothing, as lesson 1 explained.
Nothing is created. Make a directory for it and save the file below:

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
ana@laptop:~/azure/tf/synapse$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/synapse$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/synapse$ sed -i 's/DW100c/DW150c/' main.tf && terraform validate -no-color

Error: expected sku_name to be one of ["DW100c" "DW200c" "DW300c" "DW400c" "DW500c" "DW1000c" "DW1500c" "DW2000c" "DW2500c" "DW3000c" "DW5000c" "DW6000c" "DW7500c" "DW10000c" "DW15000c" "DW30000c"], got DW150c

  with azurerm_synapse_sql_pool.warehouse,
  on main.tf line 49, in resource "azurerm_synapse_sql_pool" "warehouse":
  49:   sku_name             = "DW150c"
```

**The workspace needs a Data Lake, and that is why the storage account says `is_hns_enabled = true`**:
the hierarchical namespace of lesson 3, which Synapse requires of the filesystem it is given as its
default. The administrator's password comes from a variable marked `sensitive`, never from the file,
because a file is committed and a password must not be. The serverless pool needs no declaration at
all: every workspace has `Built-in`.

**`sku_name` is the size, and the provider knows every size there is**: the list it printed for the
`DW150c` that does not exist runs from `DW100c` to `DW30000c`. **`storage_account_type` is where the
pool's backups go**, and the provider offers only `LRS` and `GRS` for it; `GRS` copies them to the paired
region, in the United States for `brazilsouth`, so Quitanda's file says `LRS`.

What the declaration cannot say is when the pool runs. **Pausing is an operation, not a property**: it
is done by a schedule, a pipeline or a person, outside this file, and a pool declared here and never
paused is billed every hour from the moment `apply` creates it. For a report that runs for an hour a
night, the pause is the largest saving available, and lesson 19's Data Factory is one of the usual
places to schedule it.
