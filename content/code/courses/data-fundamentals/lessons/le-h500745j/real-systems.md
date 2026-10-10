---
title: Where real systems sit, and why the honest answer is a setting
version: 1
---

**Very few real systems are CP or AP as a whole: most make the choice per operation, and many let
the caller make it per request.** So a label like "Cassandra is AP" is a statement about a default.
The picture below places seven systems with that caveat drawn in, and the table after it says what
each one does when a link is cut.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A triangle with P at the top, C at the bottom left and A at the bottom right. Beside the CP edge: etcd, ZooKeeper, Spanner, PostgreSQL with one primary, and Kafka with acks=all, dashed. Beside the AP edge: Cassandra and DynamoDB default reads, both dashed. Under the C-and-A edge: PostgreSQL on one machine, with no network to cut.\" data-fig=\"real-systems\"><defs><marker id=\"real-systems-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><polygon points=\"360,44 250,254 470,254\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></polygon><circle cx=\"360\" cy=\"44\" r=\"15\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">P</text><circle cx=\"250\" cy=\"254\" r=\"15\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"250\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">C</text><circle cx=\"470\" cy=\"254\" r=\"15\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"470\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">A</text><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">partitions happen: P is not optional</text><text x=\"110\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">CP: the minority side refuses</text><rect x=\"20\" y=\"58\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"20\" y=\"94\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ZooKeeper</text><rect x=\"20\" y=\"130\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spanner</text><rect x=\"20\" y=\"166\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PostgreSQL, one primary</text><rect x=\"20\" y=\"202\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"110.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Kafka, acks=all</text><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">AP: every side answers</text><rect x=\"520\" y=\"58\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Cassandra</text><rect x=\"520\" y=\"94\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"610.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">DynamoDB, default reads</text><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">C and A without P: only with no network to cut</text><rect x=\"270\" y=\"300\" width=\"180\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PostgreSQL, one machine</text><rect x=\"520\" y=\"300\" width=\"26\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"554\" y=\"308\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">moves with its settings</text></svg>", "caption": "Where seven systems sit, by default. Dashed boxes move with their settings, and the C-and-A edge holds only systems with no network to cut."}
```

The figure keeps the triangle on purpose, to show what is wrong with it. The bottom edge, C and A
without P, is where a system sits only when it has no network to be cut. **A PostgreSQL database
on one machine is there, and so is every program on your laptop.** The moment a second machine
holds a copy, the system moves to one of the other two edges. The dashed boxes are the ones whose
edge depends on how they are set up.

## Seven systems, one question each

| system | what it does when a link is cut | the caveat |
|---|---|---|
| **etcd** and **ZooKeeper** | the side with a majority keeps accepting writes; the other side refuses them | ZooKeeper may answer a read from a follower that is behind, unless the client asks it to catch up first; etcd offers a cheaper read that may be stale, if asked for |
| **Spanner** | CP: consensus within each group of copies, and Google's own network built so that partitions are rare | Brewer, by then at Google, argued in 2017 that it is CP in theory and so rarely unavailable that users can treat it as both |
| **PostgreSQL** with one primary and replicas | only the primary takes writes; a replica cut off from it keeps answering reads, with data that may be old | with synchronous replication, the primary waits for a standby to confirm each commit, and waits indefinitely if that standby is unreachable |
| **Cassandra** | answers on both sides by default, and settles conflicts by timestamp afterwards | `QUORUM` reads and writes make the minority side refuse instead |
| **DynamoDB** | its default reads may return a value that is not the latest | a strongly consistent read is one flag on the request |
| **Kafka** | each partition of a topic has one leader; with `acks=all`, a write is refused when too few copies are in sync | the settings `min.insync.replicas` and `unclean.leader.election.enable` decide whether it prefers refusing or losing messages |

Kafka is the one most data platforms meet first, and its two settings are the CAP choice spelt
out. With unclean leader election switched off, which is the default, a partition whose in-sync
copies are all gone waits for one of them to come back rather than promoting a copy that is
behind. **Waiting is the C; promoting the stale copy is the A, paid for with messages that are
lost.** A word of warning about the vocabulary: a Kafka *partition* is a slice of a topic, the
partitioning of lesson 9, and has nothing to do with a network partition. `streaming` covers both
settings on a real cluster.

## One more, because it changed

Object storage is where a data platform keeps most of its files. Amazon S3 was eventually
consistent for overwrites and deletes for most of its life: a file replaced a moment ago could be
read back in its old version. **Since December 2020 it gives strong read-after-write consistency**
for every request. Pipelines written for the old behaviour carried workarounds, such as a separate table
recording which files had been written, that are now dead weight.

That is the last reason to treat any placement on this page as a reading taken on a date. A
system's documentation states what it promises today; check it there, for the operation you are
about to depend on, before trusting a label from anywhere else, this page included.
