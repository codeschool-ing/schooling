---
title: The Data Map, sources, collections and scans
version: 1
---

**This section is taught from Microsoft's documentation and was not run**, apart from Terraform
checking a declaration offline.

**The Data Map is Purview's inventory**: one record per asset it knows about, an asset being a
storage account, a container, a folder, a file, a database, a table or a column, with the
relationships between them. Nothing appears in it on its own. Somebody registers a **source**, such
as Quitanda's data lake storage account or its Azure SQL database, and a **scan** reads that source
and writes what it found into the map.

## Collections, which are also permissions

**Sources and assets live in collections**, a tree under the root collection of the account.
Quitanda's might be one collection for the raw zone and one for the curated zone, or one per team.
The tree matters twice: it organises the catalogue, and it carries permissions, because Purview's
roles, such as who may read the catalogue, who may curate assets and who may register sources and
run scans, are granted on a collection and inherited by the collections below it. A collection tree
drawn to mirror an org chart is the usual mistake: teams reorganise more often than data moves.

## A scan, and the identity that runs it

**A scan is a job that connects to a source, reads its structure and a sample of its contents, and
writes assets and classifications into the map.** It runs on an **integration runtime**, the same
idea as Data Factory's in lesson 19: Microsoft's own runtime in Azure for sources it can reach, a
managed one inside a virtual network for sources behind private endpoints, or a self-hosted one,
installed on a machine of yours, for sources in your own data centre.

**The scan reads with an identity, and that identity needs permission to read.** The usual one is
the Purview account's own managed identity, and for a storage account Microsoft's documentation
has it granted the **Storage Blob Data Reader** role on the account. That is lesson 6's subject seen
from the other side: a catalogue that can classify every column must be able to read every column,
so the Purview account becomes one of the most privileged readers in the company, and its access
is worth reviewing like any other.

**What a scan reads is set by a scan rule set**: which file types, and which classification rules to
apply. A scan runs once or on a schedule; a full scan reads everything and an incremental one only
what changed since the last. Scans are billed by the processing they use, so the schedule is a cost
decision as well as a freshness one, and the last section prices one.

## Declaring the account

The Purview account itself is an Azure resource like the others. Declared in Terraform, in a
directory of its own as in lesson 1:

```sh
mkdir -p ~/azure/tf/purview && cd ~/azure/tf/purview
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

resource "azurerm_resource_group" "governance" {
  name     = "rg-quitanda-governance-prd"
  location = "brazilsouth"
}

resource "azurerm_purview_account" "catalogue" {
  name                        = "pview-quitanda-prd"
  resource_group_name         = azurerm_resource_group.governance.name
  location                    = azurerm_resource_group.governance.location
  managed_resource_group_name = "rg-quitanda-governance-prd-managed"
  public_network_enabled      = false

  identity {
    type = "SystemAssigned"
  }
}
```

```
ana@laptop:~/azure/tf/purview$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/purview$ terraform validate -no-color
Success! The configuration is valid.
```

**Valid, and it is the account and nothing inside it.** Sources, collections, scans and their
schedules are not Azure resources in this provider; they are configured in Purview itself, through
its portal or its own programming interface. `identity` gives the account the managed identity a
scan reads with, and `public_network_enabled = false` keeps the account off the internet, so its
portal and its interface are reached through private endpoints. The managed resource group is where
Azure places the resources Purview creates for itself; it is named here so that it does not get a
generated name nobody recognises.
