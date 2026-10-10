---
title: Versions, and the update that arrives late
version: 1
---

**When the events are updates to the same thing, a duplicate is not the only danger: an older
update can arrive after a newer one, and writing whatever arrives last puts the old value back.**
This is the *last writer wins* trap. "Last" means last to reach the database, which is not the
same as last to happen.

Within one partition of one topic, Kafka keeps order per key, lesson 3's promise, and a single
consumer applies the updates in the order they were written. The order breaks in the places
lessons 3 and 7 pointed at: a key that moved partition when partitions were added, a replay of an
old backup over newer data, two topics feeding the same table, a producer that retried without
idempotence. Each of them can hand the sink version 2 of a price after version 3.

## Keep the highest version

The cure is for each update to **carry a version**, given by whoever owns the thing being
updated, and for the sink to apply an update only if its version is higher than the one stored.
The comparison belongs in the write itself, so that two consumers racing on the same row cannot
both pass a check made earlier. In SQLite it is a `WHERE` on the conflict clause.

Three updates of the price of `bk-01`, versions 1 and 3 and then a late version 2:

```
ubuntu@stream:~/work$ python -m sqlite3 prices.db "CREATE TABLE price (book TEXT PRIMARY KEY, cents INTEGER, version INTEGER)"
```

@@VERSIONS@@

The same statement is also **idempotent**: replaying version 3 finds version 3 stored, the
condition is false, and nothing changes. A versioned upsert answers duplicates and reordering at
once, which is why it is the usual shape of a sink that keeps the current state of things, and
why lesson 14's change events carry a position from the database's log that can serve as one.

## Where the version comes from

| source of the version | sound when |
|---|---|
| a counter the owner increments on every change | one system owns the entity; this is the strongest |
| the database's log position of the change | the events come from a database's log, as in lesson 14 |
| the event's timestamp | clocks agree to finer than the gap between two updates, which lesson 9 says not to assume |
| the Kafka offset | all updates of the entity go through one partition and are never replayed from elsewhere |

**A timestamp is the tempting choice and the weak one.** Two updates in the same millisecond tie,
and a till with its clock ten minutes fast wins every argument for ten minutes. Lesson 9 is about
how often clocks disagree.
