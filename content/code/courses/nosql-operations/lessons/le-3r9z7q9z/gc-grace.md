---
title: How long a tombstone has to live
version: 1
---

A tombstone cannot live for ever: a table that deletes as much as it writes would grow without end,
and every read would wade through markers for rows deleted years ago. It cannot be dropped as soon
as it is written either. **Its whole job is to reach every replica that still holds the old value,
and some of those replicas may be down when the delete happens.** `gc_grace_seconds` is the table
setting that says how long Cassandra keeps a tombstone before compaction is allowed to throw it
away, and the default, which `DESCRIBE TABLE` showed earlier in this lesson, is `864000`: ten days.

## What happens at the end of the grace period

Compaction merges SSTables and writes out only what is still needed. A tombstone younger than
`gc_grace_seconds` is copied into the new SSTable, along with the fact that it shadows the data
beneath it. **A tombstone older than `gc_grace_seconds` is purgeable**: when compaction merges it with
the data it deleted, both are dropped, and the new SSTable holds neither. From that moment the node
has no record that the row ever existed, or that it was deleted.

That is fine on a node that saw the delete. It is a problem for a replica that did not.

## Why the grace period is about repair

Picture the three replicas of a partition. A delete at `QUORUM` reaches two of them while the third
is down. The two write tombstones; the third keeps the old row. Three things can carry the delete to
the third replica once it returns, and lesson 19 is about all three:

- **hinted handoff**: the coordinator kept the delete for the missing node and replays it when the
  node comes back, but only if the node was down for less than `max_hint_window`, three hours by
  default;
- **read repair**: a read that happens to ask that replica and another notices they differ and
  fixes the older one;
- **repair**: the `nodetool repair` command, which compares every replica of every range and copies
  what is missing.

The first two are best effort. Hints expire; a row nobody reads is never read-repaired. **Repair is
the only one that is guaranteed to visit every partition**, and it can only carry a tombstone that
still exists. So the rule follows:

> Every replica of every table must be repaired at least once every `gc_grace_seconds`.

Run repair on every node within ten days and a missed delete always reaches the stale replica while
the tombstone is still there to be copied. Let a node go longer, or let it stay down longer, and the
tombstone can be purged on the nodes that saw it while the stale copy still waits elsewhere. The
next section makes that happen.

## Changing the number

`gc_grace_seconds` is per table, set with `WITH gc_grace_seconds = …` on `CREATE TABLE` or `ALTER
TABLE`. Shortening it makes tombstones go sooner, which helps a table that deletes heavily, and
**tightens the repair deadline by exactly the same amount**. Teams lower it to a few days only when
their repairs reliably finish more often than that. Setting it to `0` is reasonable for a table that
is never deleted from and never updated in place, and dangerous anywhere else.

Two related settings exist and are worth recognising by name. A row written with a time to live
(`USING TTL`) becomes a tombstone when it expires, and that tombstone follows the same grace period.
And on a node that has been down **longer than `gc_grace_seconds`**, the standard operational
advice is not to start it back as it is, but to wipe it and let it rejoin as a new node,
because its data may hold rows whose deletes everyone else has already forgotten.
