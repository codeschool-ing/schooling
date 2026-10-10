---
title: Shards and replicas, again
version: 1
---

The lab's index has one shard and no replicas, set in `index.json`, because it runs on one node. Ask the
engine how it is laid out:

```
ana@vm:~/lab/search$ curl -s "localhost:9200/_cat/shards/products?v"
index    shard prirep state   docs  store ip         node
products 0     p      STARTED   25 12.5kb 172.18.0.3 b39dfa53a3b6
```

One primary shard, `p`, holding 25 documents, started. A production cluster looks like lesson 10 in one
product: the index is split into several **primary shards**, so a big catalogue spreads across machines
and searches run on all of them in parallel; and each primary has **replicas** on other nodes, so a
node can be lost without losing data, and replicas can answer searches too.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A search cluster of three nodes holding one index split into three primary shards, P0, P1 and P2, each with one replica, R0, R1 and R2, placed on a different node from its primary. A query is sent to one copy of every shard, and their top results are merged.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"40\" width=\"190\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"135\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">node 1</text><rect x=\"60\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">P0</text><rect x=\"140\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R2</text><rect x=\"265\" y=\"40\" width=\"190\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">node 2</text><rect x=\"285\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">P1</text><rect x=\"365\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R0</text><rect x=\"490\" y=\"40\" width=\"190\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"585\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">node 3</text><rect x=\"510\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">P2</text><rect x=\"590\" y=\"80\" width=\"70\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">R1</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">P = primary shard, R = its replica, never on the same node</text></svg>", "caption": "An index is split into shards for size and replicated for failures, lesson 10's two answers in one product."}
```

Lesson 10's warnings carry over. The number of primary shards is fixed when the index is created,
because a document's shard is its id's hash modulo that number: changing it means a new index and a
reindex, which aliases make painless and nothing makes free. And a search on a sharded index is a
**scatter-gather**: each shard returns its own best results, and the node that received the query
merges them, which is lesson 10's top-three problem solved for you, at the cost of asking every shard.

Too many shards is the more common mistake than too few. Each shard has a fixed overhead in memory and
file handles, and a catalogue of 50,000 products fits comfortably in one. The engines' own guidance is
to aim for shards of tens of gigabytes, and to start with fewer than you think.
