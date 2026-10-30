---
title: One storage layer for the whole cluster
version: 1
---

**AlloyDB is PostgreSQL running on a storage system Google built for it, and the storage is the
whole difference.** The engine that parses your SQL, plans it and keeps your transactions apart is
PostgreSQL, with the same drivers, the same `psql`, and most of the same extensions. Underneath it,
where Cloud SQL gives each instance a disk of its own, AlloyDB gives the whole cluster one regional
storage service, shared by every machine that runs the engine. Almost everything else about AlloyDB,
how it fails over, how its replicas keep up and how it is billed, follows from that change.

**The wrong idea is that AlloyDB is Cloud SQL on a bigger machine.** Lesson 6's Cloud SQL instance is
PostgreSQL on a virtual machine with a persistent disk attached; lesson 7's standby has a disk kept in
step with it, and each read replica keeps a full copy of its own. AlloyDB's machines own no disk at
all. **Nothing in this section can be run**: Google publishes no emulator for AlloyDB, and what
follows is taught from its documentation, the "AlloyDB overview" page at
cloud.google.com/alloydb/docs/overview, and from the pricing page, read on 2026-10-30. There is no
transcript here, and the lesson says the same wherever AlloyDB itself is the subject.

## The log goes down, the pages come up

**A PostgreSQL server you know writes twice.** From `sql-databases`, a change goes first to the
write-ahead log, which is what makes a commit durable, and the changed data pages are written out
later, by a checkpoint. Both writes land on the disk the server owns. That is Cloud SQL's design, and
lesson 7's replicas copy the log from that disk to theirs.

**An AlloyDB primary writes only the log, and writes it to the storage layer.** A commit is durable
once its log records are on the regional log storage, which keeps them in more than one zone of the
region. Then a component Google calls the **log processing service** reads that log and applies it to
the data blocks, in the background and spread across many servers, so that the pages exist in the
storage layer without the primary ever writing one. When an instance needs a page it does not hold
in memory, it asks the storage layer for that block, and the storage layer hands back the version the
log says is current.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"An AlloyDB cluster in southamerica-east1. Above, four nodes: the primary instance as an active node and a standby node, and a read pool of two nodes; each node keeps a cache. Below, one regional storage layer across three zones, holding the log and the blocks the log processing service builds from it. The active primary sends only log records down; the read pool nodes read blocks up from the same storage; the primary also sends its log stream to the other nodes so their caches stay correct.\" data-fig=\"l08-alloydb-storage\"><defs><marker id=\"ah-l08-alloydb-storage\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cluster quitanda-orders, one region</text><rect x=\"40\" y=\"50\" width=\"140\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">active</text><text x=\"110\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">primary instance</text><text x=\"110\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memory + local cache</text><rect x=\"190\" y=\"50\" width=\"140\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">standby</text><text x=\"260\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">primary instance</text><text x=\"260\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memory + local cache</text><rect x=\"380\" y=\"50\" width=\"140\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">node 1</text><text x=\"450\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">read pool</text><text x=\"450\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memory + local cache</text><rect x=\"530\" y=\"50\" width=\"140\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">node 2</text><text x=\"600\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">read pool</text><text x=\"600\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">memory + local cache</text><rect x=\"30\" y=\"190\" width=\"660\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">regional storage layer, shared by every node</text><rect x=\"45\" y=\"220\" width=\"200\" height=\"68\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-a</text><text x=\"145\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">log storage</text><text x=\"145\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">blocks, built from the log</text><rect x=\"260\" y=\"220\" width=\"200\" height=\"68\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-b</text><text x=\"360\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">log storage</text><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">blocks, built from the log</text><rect x=\"475\" y=\"220\" width=\"200\" height=\"68\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">southamerica-east1-c</text><text x=\"575\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">log storage</text><text x=\"575\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">blocks, built from the log</text><line x1=\"110\" y1=\"112\" x2=\"110\" y2=\"218\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l08-alloydb-storage)\"></line><text x=\"118\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">log records only</text><line x1=\"450\" y1=\"218\" x2=\"450\" y2=\"114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l08-alloydb-storage)\"></line><line x1=\"600\" y1=\"218\" x2=\"600\" y2=\"114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l08-alloydb-storage)\"></line><text x=\"458\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">blocks, on a cache miss</text><line x1=\"180\" y1=\"81\" x2=\"380\" y2=\"81\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\" marker-end=\"url(#ah-l08-alloydb-storage)\"></line><text x=\"285\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">log stream, to keep caches correct</text><line x1=\"250\" y1=\"112\" x2=\"250\" y2=\"140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line></svg>", "caption": "One cluster, one storage layer: the primary writes the log, the storage builds the pages, and every node reads them."}
```

**Each machine still keeps a cache, and keeps two.** The first is PostgreSQL's own buffer cache in
memory, the `shared_buffers` you can `SHOW` in any PostgreSQL. The second is what Google's
documentation calls the **ultra-fast cache**, a larger tier on the node's local storage, so a page
evicted from memory is still close by. A read reaches the storage service only when both miss, which
is what keeps a remote storage layer from making every query slower.

## What the shared layer changes

**Storage is a property of the cluster, and it is billed by what it holds.** There is no disk size to
choose and no size to grow: the pricing page says the regional storage "automatically scales up and
down" and that "you only pay for the storage you use". It also says that storage costs do not change
when you add read pool instances or nodes, because every instance reads the same storage. A Cloud SQL
disk is a size somebody chose, paid for in full from the first day and once more for every replica;
an AlloyDB cluster holding 37 GiB pays for 37, once.

**A replica is a reader of the same data, not a copy of it.** An AlloyDB read node does not replay
the log into pages of its own. It reads blocks from the storage layer like the primary does, and
receives the primary's log stream only to keep its caches correct. That is why AlloyDB's replicas
are documented as keeping up within a short delay that does not grow with the size of the database,
and why there is nothing to resynchronise when one is added.

**A failover moves no data**, and here the difference from Cloud SQL is smaller than it sounds. The
standby of a high-availability AlloyDB primary reads the same storage, so when the active node fails
the standby only has to take over writing. Lesson 7's Cloud SQL standby is in the same position for a
different reason, a disk replicated synchronously between two zones. Where the two designs part is
the read replicas: Cloud SQL's each hold a copy that has to be built and kept up, and AlloyDB's hold
none. The next section names the commands that build both shapes.

## What it does not change

**There is still exactly one writer.** Every write in a cluster goes through its primary instance,
and a primary is one machine at a time. The pricing page puts the ceiling at 288 vCPUs and 2,232 GiB
of memory per node, which is a very large machine and still a single one. A cluster with more read
traffic than one machine can serve adds read nodes; a cluster with more **write** traffic than the
largest machine can absorb has no next step inside AlloyDB, and that is the line where lesson 9's
Spanner begins.

**And the engine is still PostgreSQL**, which is the point of buying it. A query that is slow because
an index is missing is just as slow on AlloyDB, and fixing the index is still the cure. What the
storage layer buys is everything below the engine: durability across zones, storage that grows by
itself, replicas without copies and failover without catching up. The third section of this lesson
shows the one change AlloyDB makes above the storage, inside the engine itself.
