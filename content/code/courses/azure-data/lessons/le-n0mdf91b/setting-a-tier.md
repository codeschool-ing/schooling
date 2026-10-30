---
title: Setting a tier, on upload and afterwards
version: 1
---

**A tier is set when a blob is uploaded, or changed on a blob that already exists, and either way it
is one request.** Nothing is copied in the change: the blob keeps its name, its ETag stays meaningful
and its content is not sent again. This section does both on Azurite, which accepts the tiers and
records them, and reads back what it recorded.

Make one export for September and put it in a new container twice, once with no tier and once in
cool:

```sh
mkdir -p export
printf 'order_id,customer_id,total_cents\n09-1,c-17,4590\n09-2,c-03,12800\n' > export/orders-2026-09.csv
```

```
ana@laptop:~/azure$ az storage container create -n orders-archive -o none
ana@laptop:~/azure$ az storage blob upload -c orders-archive -n orders/2026-09/default.csv -f export/orders-2026-09.csv --no-progress -o none
ana@laptop:~/azure$ az storage blob upload -c orders-archive -n orders/2026-09/cool.csv -f export/orders-2026-09.csv --tier Cool --no-progress -o none
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/default.csv --query "properties.[blobTier, blobTierInferred, blobTierChangeTime]" -o tsv
Hot
true
2026-10-30T18:48:26+00:00
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/cool.csv --query "properties.[blobTier, blobTierInferred, blobTierChangeTime]" -o tsv
Cool
false
2026-10-30T18:48:27+00:00
```

**`blobTierInferred` is the difference.** The first blob was given no tier, so it reports the
account's default, `Hot`, and says the tier was inferred. The second was given `Cool` and says it
was not. The distinction matters on Azure when the account's default changes: an inferred tier
follows the new default, and a tier that was set on the blob stays put. The third value is when the
tier last changed, in UTC.

## Changing it

```
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n orders/2026-09/default.csv --tier Cold
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/default.csv --query "properties.[blobTier, blobTierInferred, blobTierChangeTime]" -o tsv
Cold
false
2026-10-30T18:48:29+00:00
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n orders/2026-09/default.csv --tier Frozen 2>&1 | cut -d, -f1-4
ERROR: Unknown block blob tier name. Choose among ARCHIVE, COLD, COOL, HOT
ana@laptop:~/azure$ az storage blob upload -c orders-archive -n logs/app.log -f export/orders-2026-09.csv --type append --no-progress -o none
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n logs/app.log --tier Cool 2>&1 | grep ErrorCode
ErrorCode:AccessTierNotSupportedForBlobType
```

`set-tier` moved the hot blob to cold, and the change time moved with it. The third command asked
for a tier that does not exist, and the command line refused it before sending anything. `cut` keeps
the first four names, because the rest of the message lists, by a defect of the command line itself,
the methods of a Python string. **Hot, cool, cold and archive are the four.** The last two commands
make an append blob, which `--type append` asks for, and try to tier it: Azurite refuses with
`AccessTierNotSupportedForBlobType`, as Azure does.

Microsoft documents what a change costs, and it is the part to remember from this section. Moving a
blob to a cooler tier is billed as a write in the tier it goes to. Moving it to a warmer one is billed
as a read in the tier it leaves, with that tier's price per gigabyte read. And moving a blob out of
cool, cold or archive before its minimum days counts as leaving early. A tier change is cheap for one
blob and a real line on the bill for ten million.

## The account's default, declared

The account default is a property of the account, so it lives with the control plane, and Terraform
checks its declaration. Make a directory as in lesson 1, and save the account with a default of cool:

```sh
mkdir -p ~/azure/tf/tiers && cd ~/azure/tf/tiers
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

resource "azurerm_resource_group" "archive" {
  name     = "rg-quitanda-archive-prd"
  location = "brazilsouth"
}

resource "azurerm_storage_account" "archive" {
  name                     = "stquitandaarchiveprd"
  resource_group_name      = azurerm_resource_group.archive.name
  location                 = azurerm_resource_group.archive.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}
```

```
ana@laptop:~/azure/tf/tiers$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/tiers$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/tiers$ sed -i 's/"Cool"/"Archive"/' main.tf && terraform validate -no-color

Error: expected access_tier to be one of ["Cold" "Cool" "Hot" "Premium" "Smart"], got Archive

  with azurerm_storage_account.archive,
  on main.tf line 26, in resource "azurerm_storage_account" "archive":
  26:   access_tier              = "Archive"
```

**The account default cannot be archive**, and the provider's list says so: `Cold`, `Cool`, `Hot`,
`Premium` and `Smart`. Archive is only ever set blob by blob, on purpose, because a blob that lands
in archive by default is a blob nobody can read the next morning. `Premium` is the value for premium
accounts. This account is `LRS` rather than lesson 1's `ZRS` for a reason the next section gives.
