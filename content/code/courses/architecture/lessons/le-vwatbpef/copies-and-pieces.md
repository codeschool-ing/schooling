---
title: Copies and pieces
version: 1
---

A single database server has two limits, and they are different problems. It can **fail**: a disk, a
power supply, a kernel upgrade, a region. And it can be **too small**: more data than its disks hold,
more writes than one machine can take, more reads than its processors can answer. The two have
different answers, and mixing them up is a common way to buy the wrong one.

**Replication** keeps the same data on several machines. If one fails, another has everything. Reads can
be spread across the copies, so it also helps when reads are the bottleneck. What it does not do is
make room for more data, because every copy holds all of it, or take more writes, because every write
still has to reach every copy.

**Sharding**, also called partitioning, splits the data so that each machine holds a part: the orders of
customers A to H here, I to Q there. Each machine takes the writes for its part, so writes and storage
grow with the number of machines. What it does not do is survive a failure: lose the machine with
customers A to H and those customers are gone.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two ways to use three machines for one table of orders. Replication, on the left: each machine holds all the orders, A to Z, one of them takes the writes and the other two copy it. Sharding, on the right: each machine holds a third of the orders, A to H, I to Q and R to Z, and each takes the writes for its own part.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">replication: copies</text><text x=\"535\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">sharding: pieces</text><rect x=\"40\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A–Z</text><text x=\"85\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">leader</text><rect x=\"140\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A–Z</text><text x=\"185\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">copy</text><rect x=\"240\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A–Z</text><text x=\"285\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">copy</text><rect x=\"390\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">A–H</text><text x=\"435\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own writes</text><rect x=\"490\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">I–Q</text><text x=\"535\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own writes</text><rect x=\"590\" y=\"60\" width=\"90\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">R–Z</text><text x=\"635\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">own writes</text><text x=\"185\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">survives a failure; more readers</text><text x=\"535\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">more data; more writes</text><path d=\"M360 50 L360 230\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path></svg>", "caption": "Replication keeps the same data in several places, for failures and for reads. Sharding puts different data in each place, for size and for writes. Real systems usually do both."}
```

So real systems do both: the data is split into shards, and **each shard is replicated**. Kafka does it
inside one product, as lesson 6 showed: a topic is split into partitions, which is sharding, and each
partition has replicas, which is replication. This lesson takes them one at a time, then puts them back
together.

## Before either: a bigger machine

Neither is the first thing to reach for. A single PostgreSQL server on a large machine handles more than
most businesses ever ask of it: terabytes of data and tens of thousands of transactions a second are
within reach of one well-tuned server. Scaling **up**, to a bigger machine, keeps every query, join,
constraint and transaction exactly as it was. Scaling **out**, to many machines, changes some of them,
as the second half of the lesson shows.

The usual order is: replicate early, because failures do not wait until you are big; scale up for as
long as you can; and shard when one machine, the biggest you can buy or rent, is no longer enough for
the writes or the data.
