---
title: The storage account: kind, performance and replication
version: 1
---

**Everything Azure stores as blobs, files, queues or tables lives inside a storage account.** Three
decisions are made there once, for all of it: its kind, its performance tier, and how many copies of
each byte Azure keeps and where. A container and a blob have no say in any of
them. Choosing them wrong is not fatal, but two of the three can only be changed by moving the data to
a new account.

The account is also an address. An account called `stquitandadata` answers at
`https://stquitandadata.blob.core.windows.net` for blobs, `.queue.` for queues, `.table.` for tables,
`.file.` for file shares and `.dfs.` for the Data Lake interface of lesson 3. That is why the next
section spends so long on the name.

## The kind

| kind | what it holds | when |
|---|---|---|
| `StorageV2` | blobs, files, queues, tables | the default, and the answer for almost everything |
| `BlockBlobStorage` | block and append blobs only | premium performance for blobs: small, frequent reads and writes |
| `FileStorage` | file shares only | premium file shares |
| `Storage`, `BlobStorage` | as their names say | legacy kinds, which Microsoft announced it would retire in September 2026; a new account never uses them |

**General-purpose v2, `StorageV2`, is the kind this course means whenever it says storage account.**
It is the only kind that offers every access tier of lesson 4, every replication option below and the
hierarchical namespace of lesson 3.

## Performance

**Standard** keeps data on hard disks and charges mostly for what you store. **Premium** keeps it on
solid-state disks, charges more per gigabyte and less per operation, and answers with lower and
steadier latency. Premium is a separate kind of account for blobs, which is why the table above has
`BlockBlobStorage`; you cannot switch an existing Standard account to Premium.

## Replication

Azure always keeps at least three copies of every byte. What you choose is where they are.

| option | copies | survives |
|---|---|---|
| LRS, locally redundant | 3 in one datacentre | a failed disk or server |
| ZRS, zone redundant | 3, one in each of three availability zones of the region | a whole datacentre lost |
| GRS, geo-redundant | LRS here, plus 3 more in the paired region | the whole region lost |
| GZRS, geo-zone redundant | ZRS here, plus 3 more in the paired region | both of the above |

**GRS and GZRS copy to the other region asynchronously**, so a disaster that takes the primary
region can lose the last writes that had not crossed yet. Microsoft documents no guarantee for that
gap, and describes the usual lag as under fifteen minutes. The secondary copy is not readable unless
you choose the read-access variants, RA-GRS and RA-GZRS. For `brazilsouth` the paired region is
`southcentralus`, in Texas, which matters to any company with data that should stay in Brazil: the
geo-redundant options send a copy abroad.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Four replication options as copies in zones. LRS keeps three copies in one zone of brazilsouth. ZRS keeps one copy in each of three zones. GRS keeps three in one zone plus three more in the paired region southcentralus, copied asynchronously. GZRS keeps one in each of three zones plus three in the paired region.\" data-fig=\"l01-replication\"><defs><marker id=\"l01r-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--amber)\"/></marker></defs><text x=\"250\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">primary region</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">paired region</text><text x=\"250\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">brazilsouth</text><text x=\"600\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">southcentralus</text><text x=\"40\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">LRS</text><rect x=\"110\" y=\"70\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"152\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 1</text><circle cx=\"130\" cy=\"98\" r=\"7\" fill=\"var(--phosphor)\"/><circle cx=\"152\" cy=\"98\" r=\"7\" fill=\"var(--phosphor)\"/><circle cx=\"174\" cy=\"98\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"205\" y=\"70\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"247\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 2</text><rect x=\"300\" y=\"70\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"342\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 3</text><rect x=\"540\" y=\"70\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"/><text x=\"40\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">ZRS</text><rect x=\"110\" y=\"132\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"152\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 1</text><circle cx=\"130\" cy=\"160\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"205\" y=\"132\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"247\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 2</text><circle cx=\"225\" cy=\"160\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"300\" y=\"132\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"342\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 3</text><circle cx=\"320\" cy=\"160\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"540\" y=\"132\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"/><text x=\"40\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">GRS</text><rect x=\"110\" y=\"194\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"152\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 1</text><circle cx=\"130\" cy=\"222\" r=\"7\" fill=\"var(--phosphor)\"/><circle cx=\"152\" cy=\"222\" r=\"7\" fill=\"var(--phosphor)\"/><circle cx=\"174\" cy=\"222\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"205\" y=\"194\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"247\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 2</text><rect x=\"300\" y=\"194\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"342\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 3</text><rect x=\"540\" y=\"194\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"/><circle cx=\"560\" cy=\"222\" r=\"7\" fill=\"var(--amber)\"/><circle cx=\"582\" cy=\"222\" r=\"7\" fill=\"var(--amber)\"/><circle cx=\"604\" cy=\"222\" r=\"7\" fill=\"var(--amber)\"/><line x1=\"397\" y1=\"216\" x2=\"536\" y2=\"216\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01r-ah)\"/><text x=\"466\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">asynchronous</text><text x=\"40\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">GZRS</text><rect x=\"110\" y=\"256\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"152\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 1</text><circle cx=\"130\" cy=\"284\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"205\" y=\"256\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"247\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 2</text><circle cx=\"225\" cy=\"284\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"300\" y=\"256\" width=\"85\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"342\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone 3</text><circle cx=\"320\" cy=\"284\" r=\"7\" fill=\"var(--phosphor)\"/><rect x=\"540\" y=\"256\" width=\"120\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"5 4\"/><circle cx=\"560\" cy=\"284\" r=\"7\" fill=\"var(--amber)\"/><circle cx=\"582\" cy=\"284\" r=\"7\" fill=\"var(--amber)\"/><circle cx=\"604\" cy=\"284\" r=\"7\" fill=\"var(--amber)\"/><line x1=\"397\" y1=\"278\" x2=\"536\" y2=\"278\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01r-ah)\"/><text x=\"466\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">asynchronous</text><text x=\"360\" y=\"328\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each dot is one copy of every byte; Azure keeps three wherever it keeps any</text></svg>", "caption": "Where the three copies are. Only the geo-redundant options leave the region, and they leave it asynchronously."}
```

Quitanda's choice, and the one this course uses in its declarations, is **`StorageV2`, Standard,
ZRS**. The order exports and the lake can be rebuilt from the shop's database, so losing a region is
a disaster to recover from rather than a byte to keep at any price. ZRS survives the loss of a
datacentre without sending anything out of the country.

## What Azurite has instead of an account

**Azurite has one account, always, and nobody created it.** It is called `devstoreaccount1`, and
its key is published in Microsoft's documentation. Because there is no domain name for each account
on your laptop, the account goes into the path instead of the host name:

```
ana@laptop:~/azure$ az storage blob url -c orders -n exports/2026-10-29.csv -o tsv
http://127.0.0.1:10000/devstoreaccount1/orders/exports/2026-10-29.csv
```

That URL is built by the command line from the connection string and asks nothing of Azurite, which
is why it works for a container that does not exist. On Azure the same blob is at
`https://stquitandadata.blob.core.windows.net/orders/exports/2026-10-29.csv`. **Kind, performance and
replication do not exist in Azurite at all**: they are properties of an account, and the account is
the control plane that no emulator answers.

## Declaring one, and checking the declaration

What the course can check about an account is its declaration. Make a directory for it and save the
file below in it:

```sh
mkdir -p ~/azure/tf/account && cd ~/azure/tf/account
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

resource "azurerm_storage_account" "data" {
  name                     = "stquitandadataprd"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
}
```

```
ana@laptop:~/azure/tf/account$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/account$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/account$ sed -i 's/"ZRS"/"ZZRS"/' main.tf && terraform validate -no-color

Error: expected account_replication_type to be one of ["LRS" "ZRS" "GRS" "RAGRS" "GZRS" "RAGZRS"], got ZZRS

  with azurerm_storage_account.data,
  on main.tf line 25, in resource "azurerm_storage_account" "data":
  25:   account_replication_type = "ZZRS"

```

**`validate` reads the files and the provider's schema, and asks Azure nothing**: no login, no
subscription, no network after `init`. It catches a value outside the list the provider knows, and it
cannot catch a choice Azure would refuse for reasons of its own, such as a replication option a region
does not offer. What it says is still worth having, because a typo found here is a failed deployment
that never happens, and the message names the file, the line and the list of values it would have
accepted. `RAGRS` and `RAGZRS` in that list are the read-access variants, spelt without the hyphen.
