---
title: Standard tier, replicas and the failover you run by hand
version: 1
---

**A Basic-tier instance is one Redis server, and when it fails the cache is empty.** Memorystore
replaces the node, and the new one starts with no keys, so every request misses until the cache
fills again and the database takes the whole load meanwhile. For a cache of copies that is a slow
hour. For the sessions of the previous section it is everybody logged out. **The Standard tier keeps
a replica in another zone and promotes it on its own when the primary stops answering**, which is
what the higher price of the first section buys. Creating one is a command, shown and not run:

```sh
gcloud redis instances create quitanda-cache --region=southamerica-east1 \
  --tier=standard --size=5 --redis-version=redis_7_0
```

## A replica, on your machine

The mechanism underneath is Redis replication, and it runs locally. Start a second server, a replica
of the first, in another terminal of its own:

```sh
redis-server --port 6380 --save '' --appendonly no --replicaof 127.0.0.1 6379
```

It connects to the server on 6379, copies every key it has, and from then on receives every write the
primary takes. The first copy takes a few seconds, because Redis 7.0 waits five before sending it, in
case more replicas connect and can share it. In the terminal you type into, `-p 6380` sends a command to the replica:

```
ana@laptop:~/gcp$ redis-cli -p 6380 INFO replication | grep -E '^(role|master_link_status)'
role:slave
master_link_status:up
ana@laptop:~/gcp$ redis-cli SET product:p-103 '{"name":"cafe torrado 500g","price_cents":3450}' EX 600
OK
ana@laptop:~/gcp$ redis-cli -p 6380 GET product:p-103
"{\"name\":\"cafe torrado 500g\",\"price_cents\":3450}"
ana@laptop:~/gcp$ redis-cli -p 6380 SET product:p-103 0
(error) READONLY You can't write against a read only replica.
```

**The replica answered `role:slave` with the link `up`, served the price written to the primary a
moment earlier, and refused a write of its own.** `READONLY` is the replica protecting the one rule
replication rests on: every key has one writer, the primary. The word `slave` is Redis 7.0's own in
this field. Reads may go to a replica, and that is what Memorystore's **read replicas** are: up to
five in a Standard-tier instance, from M2 up, behind a read endpoint the application sends its reads
to.

**Replication is asynchronous.** The primary acknowledges a write before the replica has it, so a
write in that gap is lost if the primary dies at that moment. For a cache this is acceptable,
because the database still holds the truth; it is one more reason the truth stays out of the cache.

## The failover, by hand

Now the primary fails. Stop it, and do what Memorystore does for a Standard instance, by hand:

```
ana@laptop:~/gcp$ redis-cli SHUTDOWN NOSAVE
ana@laptop:~/gcp$ redis-cli -p 6380 INFO replication | grep -E '^(role|master_link_status)'
role:slave
master_link_status:down
ana@laptop:~/gcp$ redis-cli -p 6380 SET product:p-104 2790
(error) READONLY You can't write against a read only replica.
ana@laptop:~/gcp$ redis-cli -p 6380 REPLICAOF NO ONE
OK
ana@laptop:~/gcp$ redis-cli -p 6380 SET product:p-104 2790
OK
ana@laptop:~/gcp$ redis-cli -p 6380 GET product:p-103
"{\"name\":\"cafe torrado 500g\",\"price_cents\":3450}"
```

**With the primary gone, the replica kept its keys and still refused writes, with its link `down`.**
`REPLICAOF NO ONE` promoted it: it stopped following anybody, and the next write was accepted. The
key written before the failure was still there. Two things this did not do, and Memorystore does.
It did not move the address the program uses, so a program still pointed at port 6379 would have kept
failing; **Memorystore's primary endpoint stays the same and is moved to the promoted node**. And
nothing built a new replica to replace the old primary, which Memorystore also does on its own.

**A failover breaks the connections that were open**, on Memorystore as here. A client has to
reconnect and retry, and the time to find out whether yours does is before a zone fails. Memorystore
for Redis has a command for exactly that, shown and not run:

```sh
gcloud redis instances failover quitanda-cache --region=southamerica-east1 \
  --data-protection-mode=limited-data-loss
```

`limited-data-loss`, the default, fails over only while the data at risk is within the service's own
thresholds; `force-data-loss` fails over whatever it costs. A team that has never run it does not know what its own application does in
the minute after.

## Shards, when one primary is not enough

**One primary takes every write and holds every key, so an instance is as large and as fast as one
machine.** Memorystore for Redis Cluster and Memorystore for Valkey split the keys into 16,384 hash
slots and divide the slots among shards, each a primary with its replicas. A key's slot is a hash of
the key, so the client computes which shard owns it and sends the command there. Adding a shard moves
some slots to it, which is how a cache grows past the memory or the writes of one node. The price is
that a command touching two keys works only if both keys are in the same slot, and the client has to
be one that speaks cluster mode, which the `redis` package of this lesson does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A Memorystore for Valkey or Redis Cluster instance of two shards, across two zones. The keys are split into 16,384 slots: shard 0001 holds slots 0 to 8191 and shard 0002 slots 8192 to 16383. Each shard has a primary, which takes the writes, and a replica in the other zone, which receives a copy and can be promoted. The client computes the key&#x27;s slot and sends the write to that slot&#x27;s primary.\" data-fig=\"g12-replication\"><defs><marker id=\"g12-replication-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker><marker id=\"g12-replication-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"200\" y=\"14\" width=\"240\" height=\"276\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"320\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">zone a</text><text x=\"320\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-a</text><rect x=\"460\" y=\"14\" width=\"240\" height=\"276\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">zone b</text><text x=\"580\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-b</text><rect x=\"16\" y=\"116\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">client</text><text x=\"96\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">slot = CRC16(key)</text><text x=\"96\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">% 16384</text><text x=\"320\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">shard 0001, slots 0 - 8191</text><rect x=\"230\" y=\"78\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primary</text><text x=\"320\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">takes the writes</text><rect x=\"490\" y=\"78\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">replica</text><text x=\"580\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reads; can be promoted</text><polyline points=\"410,106 488,106\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#g12-replication-ah-0)\"></polyline><text x=\"450\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">copy</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">shard 0002, slots 8192 - 16383</text><rect x=\"490\" y=\"186\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primary</text><text x=\"580\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">takes the writes</text><rect x=\"230\" y=\"186\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">replica</text><text x=\"320\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reads; can be promoted</text><polyline points=\"490,214 412,214\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#g12-replication-ah-0)\"></polyline><text x=\"450\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">copy</text><polyline points=\"176,136 200,136 200,106 228,106\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#g12-replication-ah-1)\"></polyline><polyline points=\"176,164 190,164 190,268 580,268 580,244\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#g12-replication-ah-1)\"></polyline><text x=\"330\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">a key's writes go to its slot's primary</text></svg>", "caption": "Two shards, each with its primary in one zone and its replica in the other: losing a zone costs one promotion per shard, and none of the data the primary had already copied. Drawn from the documentation; nothing here created one."}
```

**Memcached has none of this.** A Memorystore for Memcached instance is a set of independent nodes;
the client hashes each key to one of them, and a node that dies takes its keys with it. Nothing is
replicated and nothing fails over. Everything in this section about Memorystore comes from Google's
documentation and was not run; the replica and the promotion above were real, and they were Redis
7.0 on your own machine, not the service.
