---
title: Shards, hash slots and the keys that must share one
version: 1
---

**A clustered Redis splits its keys over several servers, shards, by a rule every client can compute:
16,384 hash slots.** A key's slot is a checksum of its name, CRC16, modulo 16,384, and each shard owns a
range of slots. Under Azure Managed Redis's OSS clustering policy, and on a clustered Premium cache, the
client computes the slot itself and sends the command to the shard that owns it. That is what lets a
cache grow past one machine, and it costs one rule: **a command that names several keys must find them
all in the same slot.**

The local Redis of this lesson is a single server and refuses every `CLUSTER` command. A second one
started with cluster support answers them: one node, given all 16,384 slots so that it serves every key.
It is still one machine and nothing like a managed cluster, but the slot of a key and the refusal of a
command across slots are the engine's, and they are the same here as on Azure:

```
ana@laptop:~/azure$ docker run -d --rm --name cluster-check redis:8.2.2 redis-server --cluster-enabled yes > /dev/null
ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER ADDSLOTSRANGE 0 16383
OK
ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER KEYSLOT product:cafe-500g
8271
ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER KEYSLOT product:cha-250g
5910
ana@laptop:~/azure$ docker exec cluster-check redis-cli MSET product:cafe-500g 2790 product:cha-250g 1590
CROSSSLOT Keys in request don't hash to the same slot

ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER KEYSLOT "{cart:c-7}:items"
9373
ana@laptop:~/azure$ docker exec cluster-check redis-cli CLUSTER KEYSLOT "{cart:c-7}:total"
9373
ana@laptop:~/azure$ docker exec cluster-check redis-cli MSET "{cart:c-7}:items" 3 "{cart:c-7}:total" 7680
OK
ana@laptop:~/azure$ docker rm -f cluster-check > /dev/null
```

**The two products are in slots 8271 and 5910, and `MSET` of both was refused with `CROSSSLOT`**, even on
a cluster of one node where both slots are on the same machine. The rule is about slots, not servers,
so code that works against one shard keeps working when the cluster grows.

**The two cart keys share slot 9373 because of the braces.** When a key contains `{…}`, only the part
inside is hashed, so `{cart:c-7}:items` and `{cart:c-7}:total` land together and a transaction or an
`MSET` over both is allowed. This is a hash tag, and it is the cluster's version of lesson 11's partition
key: everything that has to be touched together shares one, and a hash tag shared by too many keys puts
them all on one shard, which is a hot partition with a different name.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"The 16,384 hash slots, 0 to 16383, split over three shards: 0 to 5460, 5461 to 10922 and 10923 to 16383. product:cha-250g hashes to slot 5910 and product:cafe-500g to slot 8271, both on shard 2 but in different slots, so an MSET of the two is refused with CROSSSLOT. The keys {cart:c-7}:items and {cart:c-7}:total both hash to slot 9373, because only the part in braces is hashed, so an MSET of the two succeeds.\" data-fig=\"l15-slots\"><rect x=\"40.0\" y=\"90\" width=\"209.3\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"146.66015625\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">shard 1</text><text x=\"146.66015625\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0–5460</text><rect x=\"253.3\" y=\"90\" width=\"209.4\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"360.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">shard 2</text><text x=\"360.0\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5461–10922</text><rect x=\"466.7\" y=\"90\" width=\"209.3\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"/><text x=\"573.33984375\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">shard 3</text><text x=\"573.33984375\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10923–16383</text><line x1=\"270.9\" y1=\"48\" x2=\"270.9\" y2=\"88\" stroke=\"var(--amber)\" stroke-width=\"1.4\"/><circle cx=\"270.9\" cy=\"90\" r=\"3.5\" fill=\"var(--amber)\"/><text x=\"270.859375\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">product:cha-250g  →  5910</text><line x1=\"363.1\" y1=\"70\" x2=\"363.1\" y2=\"88\" stroke=\"var(--amber)\" stroke-width=\"1.4\"/><circle cx=\"363.1\" cy=\"90\" r=\"3.5\" fill=\"var(--amber)\"/><text x=\"363.0859375\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">product:cafe-500g  →  8271</text><line x1=\"406.1\" y1=\"136\" x2=\"406.1\" y2=\"180\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"/><circle cx=\"406.1\" cy=\"134\" r=\"3.5\" fill=\"var(--phosphor)\"/><text x=\"406.1328125\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">{cart:c-7}:items  {cart:c-7}:total  →  9373</text><text x=\"360\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">MSET of the two products: CROSSSLOT, though both live on shard 2</text><text x=\"360\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">MSET of the two cart keys: OK, because {cart:c-7} puts both in slot 9373</text><text x=\"40\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"680\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">16383</text></svg>", "caption": "The slots the transcript above printed, laid on three shards. A command over several keys needs them in one slot, not merely on one shard."}
```

## On Azure

**Azure Managed Redis is always clustered, and the clustering policy decides who sees the slots.** Under
the OSS policy the client sees every shard and must handle the rule above, which every current Redis
library does. Under the Enterprise policy the service presents a single endpoint, and its proxy routes
each command, so a client written for a single server connects to it unchanged. Azure Cache for Redis
offers clustering on Premium only, as the OSS kind.

**Persistence and geo-replication are what a cache needs when emptying it is not acceptable**, which is
a sign that it is being used as more than a cache. Persistence writes the data to disk, as snapshots or
an append-only log, so that a restart does not begin empty. Geo-replication keeps a copy in another
region. Both cost money and both are worth questioning first: Quitanda's catalogue cache refills itself
from Cosmos DB, and needs neither.
