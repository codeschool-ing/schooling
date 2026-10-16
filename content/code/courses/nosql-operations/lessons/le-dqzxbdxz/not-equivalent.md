---
title: Why the two are not equivalent
version: 1
---

Both copies restored the same 100,000 orders, so it is tempting to treat them as two formats of one
backup and keep whichever is smaller. **They answer different questions.** A dump is a list of
documents and the instructions for rebuilding everything else; a snapshot is the server's own state,
frozen. Each keeps something the other rebuilds or loses.

## What each one keeps

| | `mongodump --oplog` | file snapshot |
|---|---|---|
| what it copies | documents, plus index definitions | every file: documents, indexes, oplog, journal |
| size in this lesson | 810,350 bytes, compressed | 4,687,568 bytes, compressed |
| time to take it | 0.463 s | 2.713 s, with writes blocked throughout |
| indexes on restore | **built again** from the documents | already there |
| restore | `mongorestore` into any running server | start a `mongod` on the files |
| moment it represents | the end of the dump, after replaying the oplog | the instant of the lock |
| can restore one collection | yes, `--nsInclude` | no, the whole data directory or nothing |
| version it can go into | a different MongoDB version, within the tools' support | the same version, with the same storage engine |

The last two rows were not run in this lesson. They follow from what each copy is: documents can be
inserted into any server that accepts them, and data files can only be opened by a server that
reads that format.

## Size and time grow differently

At 100,000 orders every number here is a second or two, and in the lab the dump's restore took 1.924 seconds
while the server started on the snapshot answered after 2.212. **The two scale in different ways.** A snapshot's copy
and its restore are bounded by how fast the disk moves bytes, and starting the server costs the
same at any size. A dump restore inserts every document again and then builds every index from
scratch, which is work in proportion to the data times the number of indexes. On a collection of
hundreds of gigabytes with half a dozen indexes, that difference is the difference between
minutes and a working day, and it is the number a recovery-time promise has to be measured
against, on a copy of the real data.

## The sharded cluster, where a dump stops being one moment

Lesson 10's cluster makes the gap wider. **`mongodump` through `mongos` copies each shard at its
own pace, and `--oplog` is not available there**, because there is no single oplog to read: each
shard has its own. The result holds every document, and no single moment at which they were all
true together. An order written to `shard2` during the dump can be in it while the payment for that
order, written a millisecond later to `shard1`, is not.

That was not run in this lesson; it follows from how the cluster is built. A consistent backup of a
sharded cluster needs every shard and the config server captured at the same point. Coordinated
snapshots do that, and so do the backup services of the managed offerings; lesson 21 comes back to
what changes when somebody else runs the cluster.
