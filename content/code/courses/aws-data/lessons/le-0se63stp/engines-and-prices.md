---
title: Three engines and two ways to pay
version: 1
---

**ElastiCache is somebody else's machine running an in-memory key-value server, and the part AWS
manages is the machine, not your keys.** It installs the server, patches it, replaces a node that
dies and promotes a replica when a primary fails. What goes into the cache, for how long, and what
happens when it is full are still decisions your program makes, and they are most of this lesson.
The wrong picture is a faster database: a cache holds copies, it is allowed to forget them, and a
program that cannot survive a cache emptying overnight has turned the cache into a database without
the guarantees of one.

## Valkey, Redis OSS and Memcached

ElastiCache offers three engines, and two of them are nearly the same program.

| engine | what it is | what it adds over a plain key-value store |
|---|---|---|
| Valkey | the Linux Foundation's fork of Redis 7.2.4, made in 2024 when Redis left its open-source licence | data types, replication, failover, shards |
| Redis OSS | Redis up to the last open-source version ElastiCache carries | the same as Valkey |
| Memcached | an older, simpler cache: strings only, no replication, no persistence | many threads per node |

**Valkey speaks the same protocol as Redis**, answers the same commands and is reached by the same
client libraries, so a program written against one runs against the other. That is why the
practice later in this lesson uses the Redis server Ubuntu packages: what you learn about `SET`,
`EXPIRE` and eviction carries over unchanged. Memcached is the engine to choose only when all you
need is strings with an expiry and a node that uses every core; anything needing a replica, a
sorted set or a counter that survives a node is Valkey's.

The prices make the choice between the first two for you. With moto running in its own terminal
and the four lines of lesson 1's "Your lab, in brief" typed in this one, the sheet's ElastiCache
block is:

```
ana@laptop:~/aws$ python3 prices.py elasticache
AWS public price list, sa-east-1, USD, excluding tax

ElastiCache, USD
  Valkey, cache.t4g.micro, per node-hour                0.02400  hour
  Valkey, cache.r7g.large, per node-hour                0.34880  hour
  Redis, cache.t4g.micro, per node-hour                 0.03000  hour
  Redis, cache.r7g.large, per node-hour                 0.43600  hour
  Memcached, cache.t4g.micro, per node-hour             0.03000  hour
  Memcached, cache.r7g.large, per node-hour             0.43600  hour
  Serverless Valkey, data stored                        0.13300  GB-hour
  Serverless Valkey, per million ECPUs                  0.00370  million
```

**Valkey costs 20% less than Redis OSS on the same node**: 0.34880 against 0.43600 an hour for a
`cache.r7g.large`, and 0.02400 against 0.03000 for a `cache.t4g.micro`, which is 0.8 of the price
in both cases. Memcached is priced like Redis OSS. A month is 730 hours, so one `cache.r7g.large`
running Valkey is 0.34880 × 730 = 254.62 USD and the same node running Redis OSS is 318.28. With no
feature to buy, a new cache at Quitanda starts on Valkey.

## Nodes, or Serverless

**A node-based cache is machines you choose and pay for by the hour, whether they are busy or not.**
You pick the node type, which fixes the memory: a `cache.r7g.large` has 13.07 GiB and a
`cache.t4g.micro` 0.5 GiB. You pick how many, and the next section arranges them into shards and
replicas. If the data outgrows them, you add nodes or change their type.

**Serverless has no nodes to choose and charges for two quantities instead**: the data it holds,
in GB-hours, and the work it does, in ElastiCache Processing Units (ECPUs). AWS documents a simple
read or write of up to 1 KB as one ECPU, and larger values or heavier commands as more. It grows
and shrinks on its own and is spread over several zones from the start.

The two lines of the sheet make the comparison concrete for Quitanda's product catalogue cache. Say
it holds 2 GB on average and answers 500 million requests a month, all small:

| | arithmetic | USD a month |
|---|---|---|
| Serverless, data | 2 GB × 0.133 × 730 h | 194.18 |
| Serverless, requests | 500 million × 0.0037 per million | 1.85 |
| two `cache.r7g.large` Valkey nodes, primary and replica | 2 × 0.3488 × 730 | 509.25 |

**At 2 GB Serverless wins, and at 13 GB it loses**: 13 × 0.133 × 730 is 1,262.17 USD for the data
alone, against the same 509.25 for two nodes that hold 13.07 GiB each. Serverless is priced by what
you keep in it, so it suits a small cache with traffic that comes and goes. A large, steady cache
is cheaper on nodes, and the requests, which people worry about first, are the smallest line of the
three. Lesson 11 made the same trade for DynamoDB between on-demand and provisioned capacity.

**Neither of these can be practised in moto.** Asking it for a Serverless cache fails with an error
from moto itself, as the next section shows, and the node-based clusters it does create run no
server at all.
