---
title: Two services for one engine
version: 1
---

**A managed Redis is somebody else's machine running an in-memory key-value server, and the part
Microsoft manages is the machine, not your keys.** It installs the server, patches it, replaces a
node that fails and promotes a replica. What goes into the cache, for how long, and what happens when
it is full are still decisions your program makes, and they are most of this lesson. The wrong
picture is a faster database: a cache holds copies, it is allowed to forget them, and a program that
cannot survive its cache emptying overnight has made the cache into a database without a database's
guarantees.

This section is taught from Microsoft's documentation, with one declaration checked by Terraform. No
emulator answers either service; the rest of the lesson runs the Redis engine itself.

## Azure Cache for Redis, the service being retired

**Azure Cache for Redis is the older service, and Microsoft has announced its retirement**, with
Azure Managed Redis named as the service to move to. The title of this lesson keeps the older name
because it is the one most existing deployments, documents and job adverts still use. Its tiers are
worth knowing for exactly that reason, because a cache already running somewhere is in one of them:

| tier | what it is |
|---|---|
| Basic | one node, no replica and no service level agreement; for development |
| Standard | a primary and a replica, with failover |
| Premium | Standard on faster machines, plus clustering, persistence to disk, network isolation and geo-replication |
| Enterprise, Enterprise Flash | Redis Enterprise software, with its modules and active geo-replication |

**Two of its defaults matter to a program.** The documented default eviction policy is
`volatile-lru`, which the eviction section below tests, and the plain-text port 6379 is disabled by
default, so clients connect with TLS on 6380. Several administrative commands, `CONFIG` among them, are blocked,
because the server's settings belong to the service.

## Azure Managed Redis, the one to choose now

**Azure Managed Redis runs Redis Enterprise software on every tier**, and its tiers are named for what
the memory is balanced against rather than for how many features they unlock. The provider Terraform
uses lists every size it accepts, which makes it the quickest check of the names: Memory Optimized,
Balanced, Compute Optimized and Flash Optimized, each in sizes. Flash Optimized keeps part of the data
on fast disk instead of memory.

**Clustering is not a premium feature here: the data is always spread over shards**, and what you
choose is how clients see it. Under the OSS clustering policy a client talks to each shard directly and
has to understand Redis Cluster, the hash slots of the last section. Under the Enterprise policy the
service presents one endpoint and routes for the client. High availability, a replica of every shard,
is on unless you turn it off, which is only sensible for development.

Prices are per hour of the size you pick, and lesson 1's price sheet prints them: none is quoted here.

## The declaration

Quitanda's catalogue cache, as Terraform would declare it. Make a directory, save the file in it, and
check it:

```sh
mkdir -p ~/azure/tf/redis && cd ~/azure/tf/redis
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

resource "azurerm_managed_redis" "catalogue" {
  name                      = "redis-quitanda-catalogue-prd"
  resource_group_name       = azurerm_resource_group.data.name
  location                  = azurerm_resource_group.data.location
  sku_name                  = "Balanced_B1"
  high_availability_enabled = true

  default_database {
    clustering_policy = "OSSCluster"
    eviction_policy   = "VolatileLRU"
  }
}
```

```
ana@laptop:~/azure/tf/redis$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/redis$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/redis$ sed -i 's/"VolatileLRU"/"volatile-lru"/' main.tf && terraform validate -no-color

Error: expected default_database.0.eviction_policy to be one of ["AllKeysLFU" "AllKeysLRU" "AllKeysRandom" "NoEviction" "VolatileLFU" "VolatileLRU" "VolatileRandom" "VolatileTTL"], got volatile-lru

  with azurerm_managed_redis.catalogue,
  on main.tf line 28, in resource "azurerm_managed_redis" "catalogue":
  28:     eviction_policy   = "volatile-lru"
```

**`sku_name` is the tier and the size in one string, `Balanced_B1`**, and the list the provider printed
when given a wrong eviction policy is the eight policies of Redis, spelt the way Azure spells them:
`VolatileLRU` for Redis's `volatile-lru`. Both are checked against the provider's schema and nothing
else. `OSSCluster` is the clustering policy that makes clients see the shards, which the last section
of this lesson explains; `high_availability_enabled` gives every shard a replica. Whether `Balanced_B1`
is offered in `brazilsouth` is Azure's question, and `validate` cannot ask it.
