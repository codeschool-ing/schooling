---
title: Change data capture in production
version: 1
---

The lab's version has every moving part of change data capture and none of the engineering. What a
production setup adds, piece by piece, is worth knowing even before you meet one.

**The plugin.** `pgoutput`, built into PostgreSQL, sends changes in a binary format over the
replication protocol and filters them by a **publication** — `CREATE PUBLICATION wh FOR TABLE
customers, orders` — so the reader receives only the tables it asked for. `wal2json` is a common
alternative that writes JSON. `test_decoding` is for learning.

**The first copy.** The lab copied the customers after creating the slot and relied on the apply
script being safe to repeat. The exact version creates the slot over the replication protocol and
asks PostgreSQL to **export the snapshot** it was created at: the initial copy then reads exactly
the moment the stream starts from, so nothing is missed and nothing applied twice.

**The reader.** Debezium is the best-known open-source reader: it connects as a replication client,
takes the initial snapshot, follows the slot, and turns each change into a message — on Kafka, as
a Kafka Connect source, or on other transports through Debezium Server. Each message carries the old
row, the new row, the operation, the table and the LSN, which is the same information the lab's
lines carry, in JSON. **None of this ran in the lab**: no Kafka, no Kafka Connect, no Debezium. What
is described here is from their documentation, not from a recording.

**Where the changes land.** Usually not straight in a warehouse table. The changes go to a log
(Kafka, or a raw table of change rows) and the warehouse table is built from that log, so the
history of every row is kept and the copy can be rebuilt — lesson 2's raw layer again, one row per
change instead of one per extraction.

## A different source: the outbox

Sometimes the cleanest answer is not to read the source's tables at all. In the **outbox pattern**
the application writes, in the same transaction as its own change, a row describing it to an
`outbox` table: *order 117013 was refunded, amount, reason*. CDC reads only that table. The events
are designed by the people who understand them, the internal tables can be refactored freely, and
the pipeline no longer depends on how the shop happens to store an order.

The price is that the application has to do it, which makes it a conversation with the source's
developers. **For a database somebody else owns and will not change, CDC on the tables is the tool;
for an application you build together, the outbox is usually the better contract.**
