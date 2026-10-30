---
title: Four products and the way each is billed
version: 1
---

**Memorystore is somebody else's machine running an in-memory key-value server, and the part Google
manages is the machine, not your keys.** It installs the server, patches it in a maintenance window
you choose, replaces a node that dies and promotes a replica when a primary fails. What goes into the
cache, for how long, and what happens when it is full are still decisions your program makes, and
they are most of this lesson. The wrong picture is a faster database: a cache holds copies, it is
allowed to forget them, and a program that cannot survive a cache emptying overnight has turned the
cache into a database without the guarantees of one.

## Redis, Redis Cluster, Valkey and Memcached

Memorystore is four products under one name, and three of them speak the same protocol.

| product | what it is | how it grows |
|---|---|---|
| Memorystore for Redis | one Redis instance, Basic or Standard tier, up to 300 GB | a larger capacity, or up to five read replicas |
| Memorystore for Redis Cluster | Redis split into shards, each a primary with replicas | more shards |
| Memorystore for Valkey | the same shape for Valkey, the Linux Foundation's fork of Redis made in 2024 when Redis left its open-source licence | more shards |
| Memorystore for Memcached | an older, simpler cache: strings only, no replication, no persistence | more nodes |

**Valkey speaks the same protocol as Redis**, answers the same commands and is reached by the same
client libraries, so a program written against one runs against the other. That is why the practice
in this lesson uses the Redis server Ubuntu packages: what you learn about `SET`, `EXPIRE` and
eviction carries over unchanged to all three. Memcached is the product to choose only when all you
need is strings with an expiry and many threads per node; anything needing a replica, a sorted set
or a counter that survives a node belongs in one of the others.

**The first product is billed by the gibibyte you provision, the next two by the node, and Memcached
by the processor and the memory.** That is the difference worth carrying out of this section,
because it decides what an idle cache costs, which is all of it in every case: each pricing page
says that charges start when the instance is created, whether you use it or not.

## The prices, read on 2026-10-30

São Paulo, `southamerica-east1`, in USD. **Memorystore for Redis**, from
cloud.google.com/memorystore/docs/redis/pricing, per GiB of provisioned capacity per hour:

| capacity tier | Basic | Standard |
|---|---|---|
| M1, 1 to 4 GiB | $0.087 | $0.146 |
| M2, 5 to 10 GiB | $0.054 | $0.103 |
| M3, 11 to 35 GiB | $0.042 | $0.083 |
| M4, 36 to 100 GiB | $0.035 | $0.069 |
| M5, over 100 GiB | $0.027 | $0.054 |

**The price per gibibyte falls as the instance grows**, and the tier is decided by the capacity you
provision, not by what the keys use. **Memorystore for Valkey**, from
cloud.google.com/memorystore/docs/valkey/pricing, per node per hour, and Memorystore for Redis
Cluster's page lists the same prices for the same node types:

| node type | capacity | per node-hour |
|---|---|---|
| shared-core-nano | 1.4 GB | $0.0505 |
| standard-small | 6.5 GB | $0.2263 |
| highmem-medium | 13 GB | $0.3054 |
| standard-large | 26 GB | $0.905982 |

**Memorystore for Memcached**, from cloud.google.com/memorystore/docs/memcached/pricing: $0.0795 per
vCPU-hour, plus $0.007 per GiB-hour for a node of up to 4 GiB and $0.0142 per GiB-hour above that.
The arithmetic, at 730 hours a month:

```
ana@laptop:~/gcp$ python3 -c 'print(round(5 * 0.054 * 730, 2), round(5 * 0.103 * 730, 2), round(4 * 0.087 * 730, 2), round(4 * 0.146 * 730, 2))'
197.1 375.95 254.04 426.32
ana@laptop:~/gcp$ python3 -c 'print(round(2 * 0.3054 * 730, 2), round(6 * 0.3054 * 730, 2), round((0.0795 + 4 * 0.007) * 730, 2))'
445.88 1337.65 78.47
ana@laptop:~/gcp$ python3 -c 'print(round(13 * 0.00087008 * 730, 2))'
8.26
```

**A 5 GiB Redis instance is 197.10 dollars a month in Basic and 375.95 in Standard.** Standard is the
tier with a replica in another zone and automatic failover, and it costs nearly twice as much,
which is the price of a second copy of the memory. Below 5 GiB the gap is the same shape and the
price per gibibyte is higher: 4 GiB is 254.04 in Basic and 426.32 in Standard, because 4 GiB falls in
M1 and 5 GiB in M2. **One GiB more can cost less**, and that is the first thing to check when the
capacity of an instance is chosen.

**A Valkey shard of two `highmem-medium` nodes, a primary and a replica, is 445.88 dollars a month,
and three such shards 1,337.65.** The page's own example says the same thing in words: the hourly
cost is the number of shards plus the number of replica nodes, multiplied by the price per node. A
Memcached node with one vCPU and 4 GiB is 78.47 dollars a month. The third command
belongs to the next part of this section. 

## What else is on the bill

**Persistence is an option, and on Valkey it has a price of its own.** A Memorystore cache keeps its
keys in memory, and can also write them out, as periodic snapshots (RDB) or, on Redis Cluster and
Valkey, as an append-only log of every write (AOF), so that a restarted node comes back with its keys.
The Valkey page charges AOF at $0.00087008 per GB-hour of instance size, which for one 13 GB node is
the 8.26 dollars a month of the third line, and backups at $0.00019444 per GB-hour with a minimum of 24
hours per backup. **A cache that needs persistence is a hint that the data in it is not a copy**, and
the sections on eviction and on failover come back to what that means.

**The network inside a region is free on the Redis page, and nearly free on the Valkey one.**
Memorystore for Redis charges nothing for traffic with a client in the same region, though the client
may pay its own cross-zone charge; the Valkey page charges $0.01 per GiB processed for clients in a
different zone from the instance. A client in another region pays for every gibibyte, which is why
the cache sits next to the program that reads it.

**Maintenance is Google's, on a weekly window you choose.** Google patches the server in that window.
A Standard-tier instance fails over to its replica for it, and the documentation warns that a
Basic-tier instance is flushed, losing every key, in maintenance and when its capacity is changed.
For a cache of copies, that is a slow hour after a maintenance night; for anything else it is the
reason Basic is the wrong tier.

**Nothing in this course creates any of them.** There is no emulator for Memorystore, Google publishes none, and the control plane
that would create an instance is not on this laptop. The cache the rest of the lesson uses is real
and runs on your own machine; the managed half is taught from the documentation and marked as such.
