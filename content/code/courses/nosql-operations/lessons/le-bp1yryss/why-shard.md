---
title: When one machine stops being enough
version: 1
---

A replica set is three copies of the same data, so **it multiplies safety and not capacity**. Every
member stores everything, and every write lands on the one primary. When the data no longer fits
on one machine's disk, or the writes no longer fit in one machine's processors, adding secondaries
does not help: each new one is another full copy that has to keep up with the same primary.

Sharding is the other direction. **The collection is cut into ranges of a field, the shard key, and
each range lives on one shard.** A shard is a replica set of its own, so every piece keeps lesson
9's guarantees, and each shard holds only its part of the data and takes only the writes for that
part.

## The three kinds of server

| server | what it does | what it stores |
|---|---|---|
| `mongos` | the router: takes every client's request and sends it to the shards that hold the data | nothing |
| config server | holds the map, which range of which collection lives on which shard | the cluster's metadata |
| shard | runs the queries and writes for its ranges | its part of each sharded collection |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"The parts of a sharded cluster. Clients send every request to mongos. mongos reads the map of ranges from the config server and sends each request to the shard or shards that hold the data. Each shard is a replica set holding part of the collection: here shard1 holds orders below 5001 and shard2 orders from 5001 up.\"><defs><marker id=\"arch10-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"arch10-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"arch10-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270\" y=\"15\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">application</text><rect x=\"270\" y=\"95\" width=\"160\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mongos</text><text x=\"350.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">router, stores nothing</text><line x1=\"350\" y1=\"55\" x2=\"350\" y2=\"93\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#arch10-ah-paper-dim)\"></line><rect x=\"500\" y=\"95\" width=\"180\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">config server</text><text x=\"590.0\" y=\"127.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the map of ranges</text><line x1=\"432\" y1=\"120\" x2=\"498\" y2=\"120\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#arch10-ah-amber)\" marker-start=\"url(#arch10-ah-amber)\"></line><text x=\"465.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">reads the map</text><rect x=\"90\" y=\"200\" width=\"220\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shard1</text><text x=\"200.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">replica set</text><text x=\"200.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orderId &lt; 5001</text><rect x=\"390\" y=\"200\" width=\"220\" height=\"70\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shard2</text><text x=\"500.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">replica set</text><text x=\"500.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orderId ≥ 5001</text><line x1=\"320\" y1=\"147\" x2=\"205\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#arch10-ah-phosphor)\"></line><line x1=\"380\" y1=\"147\" x2=\"495\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#arch10-ah-phosphor)\"></line></svg>", "caption": "One router, one map, two shards. The application never talks to a shard directly; mongos decides where each request goes, from the map the config server keeps."}
```

**The application talks only to `mongos`**, with the same commands it would send a replica set. A
query that names the shard key goes to the one shard that holds that range. A query that does not
goes to every shard, and `mongos` merges the answers, so it costs as much as the cluster has
shards. The rest of this lesson turns on that one difference.

## Before you shard

Sharding is the last thing to reach for, and the reason is in this lesson's title. **The shard key
decides where every document lives**, every query either uses it or pays for not using it, and
choosing again later means moving the whole collection. Lesson 7's indexes, a bigger machine, an
archive for old orders, or reads from secondaries all cost less, and each is undone in an
afternoon.

What sharding buys that none of them do is room to grow past one machine. A collection that is
already larger than one server's disk, or a write rate one primary cannot absorb, has no other
answer.
