---
title: Read replicas, the copies that run behind
version: 1
---

**A read replica is a separate instance that replays the primary's changes after they are
committed.** It has its own address, it answers queries, and it is always a little behind: the
primary commits, answers the application, and only then sends the change to the replica, which
applies it when it gets there. That gap is **replication lag**, and it is the one property of a
replica that every use of it has to be designed around.

**The wrong idea is that a replica is a backup, or a standby.** It is neither. A `DELETE` without a
`WHERE` on the primary is replayed on the replica a moment later, faithfully, so the replica protects
nothing against a mistake; the next section but one shows it doing exactly that. And because the
replication is asynchronous, a replica can be missing the last transactions when the primary dies, so
promoting it is a decision to accept that loss. The regional standby of the previous section,
synchronous at the disk, loses nothing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One write in time, across four lanes: the application, the primary in zone a, the standby disk in zone b, and a read replica. The application sends COMMIT; the primary writes it to the standby disk, which confirms it is on disk, and only then does the primary answer OK. After the OK, the primary sends the change to the read replica, which applies it later. The gap between the OK and the replica applying it is the replication lag.\" data-fig=\"l07-sync\"><defs><marker id=\"arr-l07-sync\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"arra-l07-sync\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">application</text><line x1=\"190\" y1=\"50\" x2=\"700\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">primary, zone a</text><line x1=\"190\" y1=\"110\" x2=\"700\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">standby disk, zone b</text><line x1=\"190\" y1=\"170\" x2=\"700\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"20\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">read replica</text><line x1=\"190\" y1=\"230\" x2=\"700\" y2=\"230\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"220\" y1=\"50\" x2=\"268\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"232\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><line x1=\"280\" y1=\"112\" x2=\"328\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"312\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">write</text><line x1=\"340\" y1=\"168\" x2=\"388\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"372\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">on disk</text><line x1=\"400\" y1=\"108\" x2=\"448\" y2=\"52\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-end=\"url(#arr-l07-sync)\"></line><text x=\"430\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OK</text><line x1=\"470\" y1=\"112\" x2=\"598\" y2=\"228\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#arra-l07-sync)\" stroke-dasharray=\"5 3\"></line><text x=\"546\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sent after the OK</text><circle cx=\"610\" cy=\"230\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"620\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">applied</text><line x1=\"448\" y1=\"262\" x2=\"610\" y2=\"262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"448\" y1=\"256\" x2=\"448\" y2=\"268\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"610\" y1=\"256\" x2=\"610\" y2=\"268\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"529\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">replication lag</text><text x=\"190\" y=\"280\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time, left to right</text></svg>", "caption": "The standby's disk is written before the commit returns; the replica hears of the write only afterwards. That ordering is why one loses nothing and the other runs behind."}
```

## What a replica is for

**Reads that can tolerate being a moment old.** Quitanda's analysts run a report every hour that
reads the last thirty days of orders and groups them by neighbourhood. On the primary, that report
competes with the checkout for the same CPU and the same cache. On a replica, it competes with nothing
that takes money, and if it reads orders that are a second old, nobody is harmed.

**Not reads that must see their own writes.** A customer who places an order and is sent to a page
that reads it back from a replica can be told the order does not exist, because the replica has not
replayed it yet. Anything that reads what the same user just wrote reads it from the primary.

## How Cloud SQL builds one

**A replica is created with the same command as an instance, plus the name of its primary**, and Cloud
SQL does the rest: it takes a copy of the primary's data, starts the engine on it, and connects it to
the primary with the engine's own replication, which for PostgreSQL is streaming replication of the
write-ahead log. Written out, and **not run**:

```sh
gcloud sql instances create quitanda-orders-reports \
  --master-instance-name=quitanda-orders \
  --region=southamerica-east1 --cpu=2 --memory=8GiB
```

Four things about it come from Google's documentation on replication:

- **the primary has to have automated backups on**, which the lesson 6 command left at its default;
- **a replica is billed as an instance of its own**: the pricing page says read replicas are charged
  at the same rate as stand-alone instances, so a replica of the lesson 6 instance is another 177.34
  a month;
- **a replica can be in another region**, and that is what protects against the loss of a whole region.
  The replication stream then crosses regions, and the Cloud SQL pricing page sends its egress to
  the network pricing of lesson 5;
- **a replica can be promoted**: `gcloud sql instances promote-replica quitanda-orders-reports` stops
  the replication for good and makes it a stand-alone instance that accepts writes. There is no way
  back; a new replica is a new copy.

**A cross-region replica is a disaster recovery plan only once somebody has decided when to promote
it.** If São Paulo is lost, the replica in another region has everything up to its lag and nothing
after. Promoting it is the decision to accept that loss and to point the application at a new address,
and a company that has not written that decision down makes it under pressure, which is the worst
time. The arithmetic of the stream is short: a database that writes 20 GiB of log a day sends 600 GiB a
month across the region boundary, and at the 0.14 a GiB of lesson 5's Latin America row that is the
84.0 on the line in the previous section.

**On the laptop**, the next section builds the same arrangement with the engine itself: a primary,
a streaming replica made from a copy of it, and a lag you can watch and measure.
