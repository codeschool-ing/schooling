---
title: The storage layer, six copies and a quorum
version: 1
---

**Aurora is PostgreSQL or MySQL on top of a storage system AWS built for it, and the storage is the
whole difference.** The engine that parses your SQL is the familiar one, with the same drivers and
mostly the same behaviour. Underneath, where RDS gives an instance a volume of its own, Aurora gives the
whole cluster one shared, distributed volume, spread over three zones and written six times. Everything
that makes Aurora fail over faster, replicate with less lag and cost differently follows from that one
change.

**The wrong idea is that Aurora is "RDS with faster disks".** An RDS instance writes data pages to its
volume, and Multi-AZ copies those pages to a second volume. Aurora's instances do not write data pages at
all. What follows is AWS's published design, from the paper its engineers presented at SIGMOD in 2017 and
from Aurora's documentation; none of it can be run in moto or on a laptop, and this section shows no
transcript.

## Six copies in three zones

**The volume is cut into segments of 10 GB, and each segment is stored six times: two copies in each of
three zones.** The six copies of one segment are a **protection group**. A 500 GB database is fifty
protection groups and three hundred segments, spread over hundreds of storage nodes, and the volume grows
by adding protection groups as the data grows, without anyone choosing a size.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One Aurora protection group: a 10 GB segment stored six times, two copies in each of three Availability Zones, sa-east-1a, sa-east-1b and sa-east-1c. The writer instance sends log records to all six copies; a write succeeds when 4 of the 6 have it, and a read needs 3 of the 6. With a whole zone lost, four copies remain, so writes continue.\" data-fig=\"l08-quorum\"><defs><marker id=\"arr-l08-quorum\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"260.0\" y=\"18.0\" width=\"200.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">writer instance</text><text x=\"360.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sends only log records</text><rect x=\"40.0\" y=\"100.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"60.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copy 1</text><text x=\"95.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"95.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"150.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copy 2</text><text x=\"185.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"185.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"260.0\" y=\"100.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"280.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copy 3</text><text x=\"315.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"315.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"370.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copy 4</text><text x=\"405.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"405.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"480.0\" y=\"100.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"580.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sa-east-1c</text><rect x=\"500.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"535.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copy 5</text><text x=\"535.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"535.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><rect x=\"590.0\" y=\"140.0\" width=\"70.0\" height=\"54.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"625.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copy 6</text><text x=\"625.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10 GB</text><line x1=\"360.0\" y1=\"58.0\" x2=\"625.0\" y2=\"138.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" marker-end=\"url(#arr-l08-quorum)\"></line><text x=\"590.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a zone lost: 4 copies left</text><text x=\"40.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">write: 4 of 6 copies</text><text x=\"40.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">read: 3 of 6 copies</text><text x=\"250.0\" y=\"262.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">4 + 3 &gt; 6: every read meets a copy with the latest write</text></svg>", "caption": "One protection group: six copies of a 10 GB segment, two per zone, written by quorum."}
```

**A write succeeds when four of the six copies have it; a read needs three.** That is a quorum: 4 + 3 is
more than 6, so every read set overlaps every write set in at least one copy that has the latest write.
The numbers are chosen against the failures that actually happen:

| what is lost | copies left | writes | reads |
|---|---|---|---|
| one storage node | 5 | yes, 4 of 5 | yes |
| a whole zone | 4 | yes, exactly 4 | yes |
| a whole zone and one more node | 3 | no | yes, and nothing is lost |

**Losing a zone does not stop the database writing.** That is the design target: a zone is the unit AWS
expects to fail, and with two copies in each zone, a zone down leaves four. Losing a zone and a node
elsewhere at the same time stops writes and keeps every committed byte readable, and the missing copies are
rebuilt from the survivors. A 10 GB segment is small enough to copy again quickly, which is why the
segments are that size: the window in which a second failure could find a group already short is short.

## The log is the database

**An Aurora writer sends the storage layer only its log records**: the description of each change, not
the pages it changed. The storage nodes apply those records to their copies of the pages in the
background, and build a page on demand when somebody reads it. In the engine you know from
`sql-databases` lesson 8, a write goes to the write-ahead log and the changed pages are written out later,
by a checkpoint; in Aurora the second step never leaves the engine, because the storage does it.

Two consequences, both from the design and neither run here. **A commit is a small network write**, log
records to six nodes, waiting for four, instead of pages to a disk and to a mirror of the disk. And
**replicas share the volume.** An Aurora replica does not keep a copy of the data; it reads the same
protection groups the writer writes, and receives the writer's log stream only to update the pages in its
own memory. That is why replica lag in Aurora is documented in milliseconds rather than seconds, and why
adding a replica adds no storage to the bill.

**And storage is billed by what is used.** An RDS instance pays for the 100 GiB it allocated; an Aurora
cluster pays for the gigabytes its volume holds, once, however many instances read it, and the six copies
are AWS's cost and not a line on yours. The last section of this lesson prices it.
