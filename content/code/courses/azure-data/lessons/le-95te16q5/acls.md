---
title: Access control lists on directories
version: 1
---

**With the hierarchical namespace, each directory and each file can carry its own access control
list.** A principal can then be let into `curated/` and kept out of `raw/` inside one container. On a flat
account the finest grain of permission is the container; lesson 6 shows the tools for that, shared
keys and signed URLs. People who know Linux expect the lake's lists to behave like a Linux
filesystem's, and mostly they do, with two differences that cause most of the surprises: a role
assigned in Azure is checked before any list, and a default list is copied once, when a child is
created, and never again.

This section is taught from Microsoft's documentation on access control in Data Lake Storage and
was not run. Azurite has no lists, and no emulator checks an identity from Microsoft Entra ID.

## Two layers, checked in order

**First, Azure role-based access control.** A role such as Storage Blob Data Reader, assigned on the
account or the container, grants its permission everywhere beneath. If a role grants the operation,
the lists are never consulted. **Then, the lists**, only for whoever no role let through. That order
has one blunt consequence: a role assigned too broadly cannot be narrowed by a list. Somebody with
Storage Blob Data Contributor on the account can write in a directory whose list says they may not.
The design that works gives the platform's own jobs roles, and gives people groups in lists.

## What a list holds

Each entry names who and what, in the three letters Linux uses:

| entry | means |
|---|---|
| owning user, owning group | set when the item is created, like a file's owner on Linux |
| a named user, group or service principal | anybody in Microsoft Entra ID, by object id |
| mask | the most any named entry or the owning group may have |
| other | everybody else who reached the item |

`r` is read, `w` is write and `x` is execute, which on a directory means *may pass through it*. That
last letter is the one people forget: **to read `curated/orders/2026/10.parquet`, a principal needs
`x` on `curated`, `orders` and `2026`, and `r` on the file.** A list that grants `r` on the file and
nothing on the directories above it grants nothing.

Every directory has two lists. The **access** list decides who may use the directory itself. The
**default** list is a template: when a file or directory is created inside, it starts with a copy of
it. A copy, made once. Changing a default list later changes nothing that already exists, and adding
the analysts to `curated/` today does not let them into the ten thousand files written there
yesterday. Microsoft provides a recursive operation for that, which walks the tree and changes every
item, and it costs time and operations in proportion to the files. Microsoft's documentation limits
an access list to 32 entries, which is the practical reason to put groups in lists rather than
people.

## Declaring one

The path resource from the previous section takes `ace` blocks, one per entry. This file sits beside
`main.tf` in `~/azure/tf/lake`, and Terraform reads both. The id is the object id of the analysts'
group in Microsoft Entra ID; the one below is made up for the lesson.

`acl.tf`:

```hcl
resource "azurerm_storage_data_lake_gen2_path" "curated" {
  path               = "curated"
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.lake.name
  storage_account_id = azurerm_storage_account.lake.id
  resource           = "directory"

  ace {
    type        = "group"
    id          = "6f1c2a4e-0b7d-4c55-9e3a-2d8f1b6a7c90"
    permissions = "r-x"
  }
  ace {
    scope       = "default"
    type        = "group"
    id          = "6f1c2a4e-0b7d-4c55-9e3a-2d8f1b6a7c90"
    permissions = "r-x"
  }
}
```

```
ana@laptop:~/azure/tf/lake$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/lake$ sed -i '0,/"r-x"/s//"read"/' acl.tf && terraform validate -no-color

Error: value of ace.1.permissions not valid: Permissions must be of the form [r-][w-][x-]

  with azurerm_storage_data_lake_gen2_path.curated,
  on acl.tf line 1, in resource "azurerm_storage_data_lake_gen2_path" "curated":
   1: resource "azurerm_storage_data_lake_gen2_path" "curated" {

ana@laptop:~/azure/tf/lake$ sed -i '0,/"group"/s//"role"/' acl.tf && terraform validate -no-color

Error: expected ace.1.type to be one of ["user" "group" "mask" "other"], got role

  with azurerm_storage_data_lake_gen2_path.curated,
  on acl.tf line 1, in resource "azurerm_storage_data_lake_gen2_path" "curated":
   1: resource "azurerm_storage_data_lake_gen2_path" "curated" {
```

**Two entries for one group is the pattern, not a repetition.** The first, with no `scope`, is the
access entry: the analysts may list `curated/` and pass through it. The second is the default entry,
so that every directory and file created inside later starts with the same grant. Leave the second
out and the analysts can open the directory and none of what the nightly job writes into it.

The refusals are the provider's own checks. Permissions are three characters in the order `r`, `w`,
`x`, with a hyphen for each one withheld, and the word `read` is not one of them. An entry's type is
one of the four the table above lists. None of it says whether the group exists or whether Azure
would accept the list, which is a question only an account can answer.
