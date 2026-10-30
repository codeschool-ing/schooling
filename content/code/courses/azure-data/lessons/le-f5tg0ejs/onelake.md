---
title: OneLake, and the shortcut that copies nothing
version: 1
---

**OneLake is one data lake for the whole tenant, created with it, and nobody provisions it.** There
is no storage account to name, no replication to choose and no container to create: a workspace is
a container, an item is a folder inside it, and a table is a folder inside that. This section is
taught from Microsoft's documentation and was not run; the shape it describes is the one the sixth
section writes into Azurite.

## An address, and two interfaces

**OneLake is built on ADLS Gen2 and answers its interface**, the `dfs` endpoint of lesson 3, and the
blob interface too. That is why tools that already read ADLS Gen2, such as Spark, Azure Storage
Explorer, `azcopy` and the Azure SDKs, can read OneLake with a different address and no other
change. The address puts the workspace where an ADLS account would put its file system:

| | ADLS Gen2, lesson 3 | OneLake |
|---|---|---|
| host | `stquitandalakeprd.dfs.core.windows.net` | `onelake.dfs.fabric.microsoft.com` |
| file system, or container | `curated` | the workspace: `quitanda-analytics` |
| path | `orders/` | the item, then its area: `sales.Lakehouse/Tables/orders/` |
| who signs in | whoever the account's roles allow | an Entra ID identity with a role on the workspace |

**There is one host for every tenant in the world.** OneLake knows which tenant a request is for from
the identity that signed it, not from the address, so two companies can each have a workspace
called `sales` without clashing. Access is granted on the workspace, through its roles, and on items
shared from it. There is no account key, because there is no account: the key that lesson 6 called
the root of everything does not exist here.

## A lakehouse has two halves

**Every lakehouse folder holds `Tables` and `Files`**, and the difference matters:

- **`Tables`** holds Delta tables, one folder each. Fabric finds them on its own and lists them as
  tables, readable from SQL, Spark and Power BI.
- **`Files`** holds anything, in any format: the raw CSV exports, images, JSON from an API. Nothing
  there is a table until a notebook or a pipeline loads it into `Tables`.

That is the same raw and curated split Quitanda uses on Blob Storage, with the boundary drawn by the
product: the night's export lands in `Files`, and the cleaned orders live in `Tables`.

## Shortcuts

**A shortcut is a folder in OneLake that points somewhere else**, and reading it reads the place it
points to. Nothing is copied, nothing is scheduled, and nothing goes stale. A shortcut can point to
another OneLake location, to ADLS Gen2, to Amazon S3, to Google Cloud Storage and to a few other
sources Microsoft lists; under `Tables`, a shortcut to a folder that holds a Delta table shows up as
a table.

Quitanda's nightly exports already land in a storage account outside Fabric, written by the shop's
system as the first lessons of this course describe. A shortcut puts them in the lakehouse without moving them:

- the shop keeps writing where it always has, with the same credentials, and nothing in its code
  changes;
- the lakehouse sees `Files/exports` as a folder, and a notebook reads it like any other;
- the account stays the system of record, with its own tiers, life cycle and immutability rules from
  lessons 4 and 5.

**What a shortcut does not remove is the bill at the other end.** A read through a shortcut to S3 is
a read from S3, charged by Amazon for the request and, leaving its cloud, for the egress, which is
lesson 7's arithmetic in a different currency. A shortcut to an Azure account in another region pays
the transfer between regions. And a shortcut uses a credential to reach the source, kept in a Fabric
connection: whoever may use the shortcut reads with that credential's rights, so the credential
should be allowed to read the folder it points to and nothing more.

## Mirroring, in one paragraph

**Mirroring is the other way into OneLake without a pipeline**: Fabric keeps a copy of an
operational database, such as Azure SQL Database or Cosmos DB, as Delta tables in OneLake, updated
continuously from the database's own change stream. It is a copy, unlike a shortcut, and it exists
because an operational database is not a folder of files a shortcut could point to. Quitanda could
mirror its orders database from lesson 8 instead of exporting it every night, and the lakehouse
would be minutes behind the shop rather than a day.
