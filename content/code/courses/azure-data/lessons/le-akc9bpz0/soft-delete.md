---
title: Soft delete, and the delete that can be taken back
version: 1
---

**Lesson 2 ended with an overwrite that destroyed six log lines, and nothing could bring them back.**
Blob Storage has three features that change that, and this lesson takes them in the order people
usually switch them on: soft delete, which keeps what was deleted for a while; versioning, which keeps
what was overwritten; and immutability, which refuses the delete and the overwrite in the first place.
None of them works on Azurite, as the last section of the lesson shows, so this section and most of
the next are taught from Microsoft's documentation and checked with Terraform, which reads the
declaration and asks Azure nothing.

## What soft delete keeps

**Blob soft delete keeps a deleted blob for a number of days you choose.** You can undelete it in that
time.
During those days the blob is invisible to an ordinary listing, appears in one that asks for deleted
blobs, and is billed as if it were still there. After them it is gone for good. Microsoft documents
the retention as 1 to 365 days. It also documents that, without versioning, soft delete protects an
overwrite as well: the content that was replaced is kept as a soft-deleted snapshot, which is the
older, manual cousin of the versions in the next section.

**Container soft delete is a separate switch** and protects the other kind of mistake: a whole
container deleted, with everything in it. A deleted container comes back with its blobs as they were.
The two are independent, and a design that turns on only one of them is protected against only one
of the two mistakes.

People expect soft delete to be a recycle bin they can open and browse. It is closer to a retention
rule. Nothing is moved anywhere: the blob stays where it was, marked deleted, and comes back under the
same name. And **it does not stop a delete**. A program with permission to delete still deletes; soft
delete only gives you a window to notice, measured in days, in which the restore is a single request.

## Declaring it

Soft delete and versioning are properties of the account's blob service, so they live in the control
plane and Terraform declares them. Make a directory for this lesson's declarations:

```sh
mkdir -p ~/azure/tf/protect && cd ~/azure/tf/protect
```

`account.tf`:

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

resource "azurerm_storage_account" "data" {
  name                     = "stquitandadataprd"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 14
    }

    container_delete_retention_policy {
      days = 14
    }
  }
}
```

```
ana@laptop:~/azure/tf/protect$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/protect$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/protect$ sed -i 's/days = 14/days = 400/' account.tf && terraform validate -no-color

Error: expected blob_properties.0.delete_retention_policy.0.days to be in the range (1 - 365), got 400

  with azurerm_storage_account.data,
  on account.tf line 31, in resource "azurerm_storage_account" "data":
  31:       days = 400


Error: expected blob_properties.0.container_delete_retention_policy.0.days to be in the range (1 - 365), got 400

  with azurerm_storage_account.data,
  on account.tf line 35, in resource "azurerm_storage_account" "data":
  35:       days = 400
```

This is lesson 1's exports account, `stquitandadataprd`, with a `blob_properties` block added. **Two
retention policies of 14 days**, one for blobs and one for containers. Two weeks covers a missing
export noticed at the next weekly check, and is short enough that Quitanda does not pay for months of
deleted files. The mistake is the provider's own fence, the 1 to
365 days of the documentation. `versioning_enabled` is the next section.
