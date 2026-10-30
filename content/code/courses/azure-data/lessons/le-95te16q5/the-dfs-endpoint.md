---
title: Asking Azurite for a directory, and declaring the lake
version: 1
---

**Azurite implements the blob endpoint and not the Data Lake one**, and the first command that uses
a directory shows what that looks like. It is worth seeing once, because the failure is not the
clear refusal people expect; the commands that touch only containers even appear to work. A new file
system, `lake2`, goes beside the container `lake` from the previous section:

```
ana@laptop:~/azure$ az storage fs create -n lake2 -o none && az storage container list --query "[].name" -o tsv
lake
lake2
ana@laptop:~/azure$ az storage fs directory create -f lake2 -n raw 2>&1 | tail -2
ERROR: None
ErrorCode:None
ana@laptop:~/azure$ curl -s -i -X PUT -H "x-ms-version: 2026-06-06" "http://127.0.0.1:10000/devstoreaccount1/lake2/raw?resource=directory" | tr -d "\r"
HTTP/1.1 400 Bad Request
Server: Azurite-Blob/3.37.0
Date: Fri, 30 Oct 2026 18:30:58 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Content-Length: 0
```

**The first command succeeded, and it should not reassure anyone.** `az storage fs create` made a
file system, which on the Data Lake endpoint is a container, and the library behind the command line
creates it through the blob endpoint, the one Azurite has. The listing shows `lake2` beside `lake`, as a
container, which is all it is. The next command needs a real directory, so it goes to the Data Lake
protocol, and Azurite does not understand it. The answer the command line printed, `ERROR: None`,
names no error at all.

The last command sends the same request by hand to see the answer underneath: `PUT` on a path with
`?resource=directory`, the Data Lake operation for creating a directory. Azurite answered `400 Bad
Request` with an empty body, no error code and nothing to read. **An error code of `None` is the
signature of a Data Lake operation reaching Azurite.** A program that is tested only against the
emulator never gets its directory, rename or access control code past the first call, and those
paths are exactly the ones this lesson is about.

## Declaring the lake

What can be checked offline is the declaration of an account with the namespace switched on, and of
the file system and directory inside it. Make a directory for it, as in lesson 1:

```sh
mkdir -p ~/azure/tf/lake && cd ~/azure/tf/lake
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
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "lake" {
  name               = "lake"
  storage_account_id = azurerm_storage_account.lake.id
}

resource "azurerm_storage_data_lake_gen2_path" "raw" {
  path               = "raw"
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.lake.name
  storage_account_id = azurerm_storage_account.lake.id
  resource           = "directory"
}
```

```
ana@laptop:~/azure/tf/lake$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/lake$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/lake$ sed -i 's/= "directory"/= "file"/' main.tf && terraform validate -no-color

Error: expected resource to be one of ["directory"], got file

  with azurerm_storage_data_lake_gen2_path.raw,
  on main.tf line 38, in resource "azurerm_storage_data_lake_gen2_path" "raw":
  38:   resource           = "file"
```

**`is_hns_enabled = true` is the whole difference** between this account and the one lesson 1
declared, apart from the name. The two resources after it exist only for accounts with the
namespace: a file system, and a path inside it. The provider's own list of what a path may be has
one entry, `directory`, as the refusal shows; files are data, written by the jobs, and never
declared. As in lesson 1, `validate` asked Azure nothing and created nothing.

Quitanda keeps **two accounts**: `stquitandadataprd` from lesson 1, flat, for the shop's exports and
anything an application reads by name; and `stquitandalakeprd`, with the namespace, for the lake the
analysts query. The last section of this lesson says why the split is deliberate rather than tidy.
