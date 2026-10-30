---
title: What the hierarchical namespace changes
version: 1
---

**Azure Data Lake Storage Gen2 is not a separate service. It is a storage account with one setting
switched on, the hierarchical namespace**, and that setting turns the flat list of names from
lesson 2 into a tree of real directories. The name misleads people in two directions. Some expect a
second product with its own accounts and its own price list, left over from the first Data Lake
Store that Microsoft retired. Others expect nothing more than a new address for the same blobs. The
account, the containers, the blobs and the access tiers are the ones of the last two lessons; what
changes is that a directory becomes a thing with an identity, a parent and permissions of its own.

This section is taught from Microsoft's documentation for Data Lake Storage and was not run: Azurite
has no hierarchical namespace, as the section after next shows.

## Directories become objects

On a flat account, `clicks/2026/10/29/part-0001.json` is one name with three slashes in it. On an
account with the hierarchical namespace, it is a file called `part-0001.json` inside a directory
`29`, inside `10`, inside `2026`, inside `clicks`, each of them an entry the service keeps. Three
things follow from that, and they are the reason the setting exists:

| operation | flat namespace | hierarchical namespace |
|---|---|---|
| rename a directory | copy and delete every blob under it | one operation on one entry, atomic |
| delete a directory | delete every blob under it | one operation, atomic |
| permissions | the container is the smallest unit | an access control list on each directory and file |

**Atomic is the word that matters for analytics.** A Spark job, a Synapse query or a Databricks
notebook finishes its work by writing into a temporary directory and renaming it into place. On a
flat namespace that rename is the thousand-file copy the next section counts, and a job that dies
halfway leaves half a table. On a hierarchical one it is a single step that either happened or did
not.

## The second endpoint

An account with the hierarchical namespace answers on two addresses for the same data. The blob
endpoint of lesson 1, `https://stquitandalakeprd.blob.core.windows.net`, keeps working, and every
tool in lessons 2 to 7 still uses it. The Data Lake endpoint, `https://stquitandalakeprd.dfs.core.windows.net`,
speaks a different protocol, with operations for directories, renames and access control lists, and
it is the one analytics engines are written against. In its vocabulary a container is a **file
system**, which is why the command line has a group of commands called `az storage fs`.

Spark and the tools built on it name a path in the lake with a URI of their own:

```
abfss://lake@stquitandalakeprd.dfs.core.windows.net/clicks/date=2026-10-29/part-0001.json
```

Read it from the inside out: the file system `lake`, at the account `stquitandalakeprd`, on the Data
Lake endpoint, then the path. `abfss` names the Azure Blob File System driver over TLS, which is how
Hadoop-family engines reach the account. Synapse and Databricks, in lessons 16 and 21, accept paths in
this form.

**Through the blob endpoint, a directory looks like a blob.** Microsoft documents that a program
listing an account with the hierarchical namespace through the blob interface sees each directory as
a zero-length blob carrying the metadata `hdi_isfolder=true`. A program written for a flat account
that copies every blob it lists will copy those markers too. That is harmless once known, and a
puzzle the first time a count of files comes out larger than expected.
