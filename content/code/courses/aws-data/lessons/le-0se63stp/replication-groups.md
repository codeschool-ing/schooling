---
title: Shards, replicas and the failover moto cannot show
version: 1
---

**A Valkey or Redis OSS cache on ElastiCache is a replication group, and a replication group is
shards, each made of one primary and some replicas.** The primary takes every write for its share
of the keys. A replica receives a copy of those writes a moment later and can answer reads. Two
choices decide the shape, and they are independent: how many shards the keys are split across, and
how many replicas each shard keeps.

**With cluster mode disabled there is one shard**, so every key lives on one primary, with up to
five replicas beside it. The whole dataset has to fit in one node's memory, and every write goes
through one machine. That is the simple case, and a client needs to know only two addresses: the
primary endpoint for writes and the reader endpoint for reads.

**With cluster mode enabled the keys are split into 16,384 hash slots** and the slots are divided
among the shards, up to 500 of them. A key's slot is a hash of the key, so the client computes which
shard owns it and sends the command there. Adding a shard moves some slots to it, which is how a
cache grows past the memory of one node or the writes of one primary. The price is that a command
touching two keys works only if both keys are in the same slot, and the client has to be one that
understands cluster mode.

**Automatic failover is what makes a replica worth paying for.** When a primary stops answering,
ElastiCache promotes one of its replicas, points the primary endpoint at it and builds a new replica
to replace the old primary. **Multi-AZ** puts the replicas in different availability zones from
their primary and requires automatic failover, so losing a whole zone costs a promotion rather than
the shard. Replication is asynchronous: a write the primary had acknowledged and not yet sent on is
lost in a failover. For a cache that is acceptable, because the database still holds the truth, and
it is one more reason the next sections keep the truth out of the cache.

**Memcached has none of this.** A Memcached cluster is a set of independent nodes; the client hashes
each key to one of them, and a node that dies takes its keys with it. Nothing is replicated and
nothing fails over.

## What moto records

moto accepts a Memcached cluster and a replication group in cluster mode, and records each one as
a document:

```
ana@laptop:~/aws$ aws elasticache create-cache-cluster --cache-cluster-id quitanda-pages --engine memcached --cache-node-type cache.t4g.micro --num-cache-nodes 2 --query "CacheCluster.[CacheClusterStatus,Engine,NumCacheNodes]" --output text
available	memcached	2
ana@laptop:~/aws$ aws elasticache create-replication-group --replication-group-id quitanda-catalog --replication-group-description "product pages" --engine valkey --cache-node-type cache.r7g.large --cluster-mode enabled --num-node-groups 2 --replicas-per-node-group 1 --automatic-failover-enabled --multi-az-enabled --query "ReplicationGroup.[Status,ClusterMode,AutomaticFailover,MultiAZ,EngineVersion]" --output text
available	enabled	enabled	enabled	None
ana@laptop:~/aws$ aws elasticache describe-replication-groups --replication-group-id quitanda-catalog --query "ReplicationGroups[0].NodeGroups[].NodeGroupMembers[].[CacheClusterId,CacheNodeId,CurrentRole,PreferredAvailabilityZone]" --output text
quitanda-catalog-0001-001	0001	None	us-east-1a
quitanda-catalog-0001-002	0001	None	us-east-1b
quitanda-catalog-0002-001	0002	None	us-east-1a
quitanda-catalog-0002-002	0002	None	us-east-1b
```

**The replication group came back `available` on the same line**, with two shards of two members
each. On AWS, creating it takes minutes, and the status would be `creating` first. Two details of
the answer are moto's rather than AWS's, and each is a reason not to trust an imitation's detail.
The engine version is `None`, where AWS would name the Valkey version it installed. And the zones
are `us-east-1a` and `us-east-1b`, in a group created in São Paulo.

There is no server behind any of it. No endpoint moto hands out resolves, no port answers, and no
key can be written. And two operations fail inside moto itself:

```
ana@laptop:~/aws$ aws elasticache test-failover --replication-group-id quitanda-catalog --node-group-id 0001

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
ana@laptop:~/aws$ aws elasticache create-serverless-cache --serverless-cache-name quitanda-catalog-sl --engine valkey

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

**A failover cannot be tested here**, and that is the operation worth testing most. On AWS,
`test-failover` promotes a replica of the shard you name, and running it before a real failure is
how a team finds out whether its client reconnects or keeps writing to a node that is now a replica.
And **Serverless cannot be created at all**: moto answers with an error page of its own, a 500,
which is a fault in the imitation and not an answer AWS would give. Everything this section says
about failover comes from AWS's documentation and was not run. The cache the rest of this lesson
uses is real, and it runs on your own machine.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A replication group with cluster mode enabled, across two availability zones. The keys are split into 16,384 slots: shard 0001 holds slots 0 to 8191 and shard 0002 slots 8192 to 16383. Each shard has a primary, which takes the writes, and a replica in the other zone, which receives a copy and can be promoted. The client computes the key&#x27;s slot and sends the write to that slot&#x27;s primary.\" data-fig=\"l13-replication\"><defs><marker id=\"l13-replication-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker><marker id=\"l13-replication-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"200\" y=\"14\" width=\"240\" height=\"276\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"320\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">zone a</text><text x=\"320\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"460\" y=\"14\" width=\"240\" height=\"276\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">zone b</text><text x=\"580\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"16\" y=\"116\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"96\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">client</text><text x=\"96\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">slot = CRC16(key)</text><text x=\"96\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">% 16384</text><text x=\"320\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">shard 0001, slots 0 - 8191</text><rect x=\"230\" y=\"78\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primary</text><text x=\"320\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">takes the writes</text><rect x=\"490\" y=\"78\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">replica</text><text x=\"580\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reads; can be promoted</text><polyline points=\"410,106 488,106\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-replication-ah-0)\"></polyline><text x=\"450\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor-dim)\">copy</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">shard 0002, slots 8192 - 16383</text><rect x=\"490\" y=\"186\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">primary</text><text x=\"580\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">takes the writes</text><rect x=\"230\" y=\"186\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">replica</text><text x=\"320\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reads; can be promoted</text><polyline points=\"490,214 412,214\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l13-replication-ah-0)\"></polyline><text x=\"450\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor-dim)\">copy</text><polyline points=\"176,136 200,136 200,106 228,106\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-replication-ah-1)\"></polyline><polyline points=\"176,164 190,164 190,268 580,268 580,244\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l13-replication-ah-1)\"></polyline><text x=\"330\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">a key's writes go to its slot's primary</text></svg>", "caption": "Two shards, each with its primary in one zone and its replica in the other: losing a zone costs one promotion per shard, and none of the data the primary had already copied."}
```
