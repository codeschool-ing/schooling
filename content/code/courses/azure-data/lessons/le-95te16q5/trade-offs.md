---
title: When to switch it on, and the setting you cannot take back
version: 1
---

**The hierarchical namespace is chosen per account, and once it is on it stays on.** Microsoft's
documentation is plain about the direction: an account without it can be upgraded to have it, and an
account with it can never go back. That puts it beside lesson 1's kind and performance tier, the account
decisions that cannot be undone without moving the data, and it is why Quitanda has two accounts
rather than one with the setting switched on for everything.

This section is taught from Microsoft's documentation and was not run, apart from its last command.

## What it costs to have it

People expect a trade between price and speed. The real trade is between two sets of features.

**For analytics, the namespace is the answer.** Atomic renames and deletes of directories, lists on
each directory, and the Data Lake endpoint that Spark, Synapse and Databricks are built against. A
lake that analytics engines write into without it pays the copy-and-delete cost from earlier in this
lesson every time a job commits, and risks the half-written directory every time one fails.

**For an application's files, it buys little and can take something away.** A shop that stores
product photos, invoices or the nightly export by exact name never renames a directory and never
needs a list per folder. And Microsoft keeps a table of Blob Storage features by account type,
because some features have arrived later, or with limits, on accounts with a hierarchical namespace.
Several of the protection features of lesson 5 have been on that table. Read the current table for
every feature a design leans on before switching the namespace on, because after that, a feature it
lacks cannot be had on the same account.

**The upgrade of an existing account is one way and has preconditions.** Microsoft's documentation
describes a validation step that checks the account for features incompatible with the namespace and
refuses to upgrade until they are gone. It is a migration with a plan, not a checkbox.

## Quitanda's two accounts

| account | namespace | holds | why |
|---|---|---|---|
| `stquitandadataprd` | flat | the shop's nightly exports, files read by exact name | lesson 1's account; it needs every protection feature of lesson 5 |
| `stquitandalakeprd` | hierarchical | `raw/`, `curated/`, `clicks/` and the analysts' tables | engines commit by renaming directories, and access differs per directory |

The exports travel from the first account to the second each night, which is a copy Quitanda pays
for once per file. That is cheaper than paying for the wrong namespace on every operation, in either
direction.

## How to tell which one you have

On Azure, the account's properties say so: `az storage account show` prints `isHnsEnabled`, true or
false, and the Data Lake endpoint answers only when it is true. That command asks Azure Resource
Manager, the control plane, so here it ends where lesson 1's `show-connection-string` did:

```
ana@laptop:~/azure$ az storage account show -n stquitandalakeprd --query isHnsEnabled 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

In the lab the answer is always the same: Azurite's account is flat, and every rename in
this course that is not on Azure is a copy and a delete.
