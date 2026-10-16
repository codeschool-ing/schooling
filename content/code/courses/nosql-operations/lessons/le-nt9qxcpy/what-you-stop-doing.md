---
title: What you stop doing
version: 1
---

The pitch for a managed database is that somebody else runs it, and the version people repeat is
that **you stop operating it**. You stop doing about half of what the last nineteen lessons did, and
the half you keep is the half that decides whether the data is right. This lesson has nothing to
type: no cloud account exists for this course, so **no command was run against any provider**, and
every product here is named from its public documentation rather than shown on a screen.

## The providers, by product

Each of the three has a service run by the company that makes it, and several run by cloud
providers:

| product | run by its maker | run by a cloud provider |
|---|---|---|
| MongoDB | MongoDB Atlas | Amazon DocumentDB and Azure Cosmos DB for MongoDB, which are other engines speaking MongoDB's protocol (next sections) |
| Redis | Redis Cloud | Amazon ElastiCache, Google Cloud Memorystore, Azure Cache for Redis |
| Cassandra | DataStax Astra DB, from the company that has long been Cassandra's main commercial backer | Amazon Keyspaces and Azure Cosmos DB for Apache Cassandra, again other engines |

## The line between the two of you

Providers call it the **shared responsibility model**, and every one of them draws it in roughly the
same place:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"A stack of responsibilities for a managed database, split by a line. Above it, yours: the data model and indexes, the shard key and consistency settings, the eviction policy, capacity and its bill, restore drills, and access. Below it, the provider's: backups and their storage, the failover machinery, patching, and the machines.\"><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">yours</text><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">decisions about the data</text><rect x=\"200\" y=\"14\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"277.5\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">data model, indexes</text><rect x=\"365\" y=\"14\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"442.5\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">shard key, consistency</text><rect x=\"530\" y=\"14\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"607.5\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">eviction policy</text><rect x=\"200\" y=\"54\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"277.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">capacity, and the bill</text><rect x=\"365\" y=\"54\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"442.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">restore drills</text><rect x=\"530\" y=\"54\" width=\"155\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"607.5\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">who has access</text><line x1=\"30\" y1=\"112\" x2=\"670\" y2=\"112\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></line><text x=\"350\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the shared responsibility line</text><text x=\"110\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">the provider's</text><text x=\"110\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">operating the software</text><rect x=\"220\" y=\"150\" width=\"440\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">backups and their storage</text><rect x=\"220\" y=\"192\" width=\"440\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">replication and failover machinery</text><rect x=\"220\" y=\"234\" width=\"440\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">patching, minor upgrades</text><rect x=\"220\" y=\"276\" width=\"440\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">machines, disks, network</text></svg>", "caption": "The line sits where the decisions about your data begin. Everything below it is operated for you; everything above it is carried out as you decided, right or wrong."}
```

Below the line is everything this course did with `docker run`, `rs.initiate()`, `--replicaof`,
`nodetool repair` and a cron job. Specifically:

- **The machines and their failures.** A disk that dies is replaced and the node rebuilt from its
  peers, without a ticket from you.
- **Patching.** Security fixes to the operating system and minor versions of the database are
  applied in a maintenance window that you choose and the provider runs. Major versions are usually
  still started by you, because they can change behaviour your application depends on.
- **The failover machinery.** The replica set, the Sentinel, the ring of nodes are built for you
  across availability zones. The election of lesson 9 still happens; you no longer build the
  members it happens between.
- **Backups and their storage.** Snapshots on a schedule, kept for a retention you choose, in
  storage the provider pays to make durable, and often a point-in-time restore on top.
- **The monitoring of lesson 20**, collected and graphed in the provider's console, with alerts you
  configure rather than exporters you run.

## What does not go away with them

**A failover is still a failover.** The provider promotes a new primary in seconds, and during those
seconds the connections your application held are dropped and its in-flight writes get errors.
Retrying those writes and reconnecting to the new primary belong to the application, as they did
in lessons 9 and 15, and no service can write that code for you.

**Managed is not the same as unlimited.** Every plan has a size: memory for a Redis, storage and
operations per second for the others. Reaching it looks exactly as it did in lessons 14 and 20,
evictions or refused writes, with the difference that the fix is a larger plan and a larger
invoice rather than a larger VM.

**And a backup the provider takes is still only a backup until somebody restores it**, which is
the first item of the next section.
