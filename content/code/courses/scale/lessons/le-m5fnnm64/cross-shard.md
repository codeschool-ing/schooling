---
title: What gets hard across shards
version: 1
---

Within one shard, everything is still a database: transactions, joins, unique constraints, a
`count(*)` that is right. **Across shards, each of those becomes the program's job**, and some of
them become impossible to do cheaply. These are the ones that bite first.

## Questions about everything

A query with no shard key in it is sent to every shard, and the answers merged. This is called
**scatter-gather**, and the router of the last section did it for the top three shows. Its costs:

- **It is as slow as the slowest shard.** The program waits for every answer, so one shard in the
  middle of a backup sets the time for the whole query. Lesson 11 comes back to this as tail
  latency.
- **It does not scale.** With ten shards, every such query does ten queries of work. Adding shards
  makes the routed queries cheaper and these more expensive.
- **Not every answer merges.** A top three merges: each shard's top three contains every row that
  could be in the overall top three. A sum or a count merges by adding. An **average does not**:
  the average of two averages is wrong unless both shards had the same number of rows, so each
  shard must return a sum and a count instead. A **median or a percentile does not merge at all**
  from per-shard medians; it needs the values, or a summary built for merging, like the histograms
  of lesson 7.

## Transactions

A sale of a ticket touches one shard. A transfer of a ticket from one buyer to another, if buyers
were the shard key, would touch two, and **there is no ordinary transaction across two servers**.
Either both changes happen or neither, and two independent databases cannot promise that by
themselves. The options are a two-phase commit, which PostgreSQL supports with `PREPARE
TRANSACTION` and which blocks both shards if the coordinator dies at the wrong moment; or a saga,
a sequence of local transactions with a compensating step for each, which `architecture` lesson 14
describes. Both are expensive enough that **the shard key is chosen so that the common operations
stay inside one shard**.

## Uniqueness and ids

`bigserial` gives each row the next number of a sequence, and each shard has its own sequence, so
**two shards hand out the same ids**. Unique constraints have the same problem: each shard checks
its own rows only, so a username that must be unique across the system has to be checked by
something that sees all shards, or be its own shard key. The usual answer for ids is to stop
counting and generate them where the row is created: a UUID, or a scheme that puts the time and the
shard number inside a 64-bit number.

## Joins

A join between two tables sharded by the same key, on that key, stays inside each shard. A join
between tables sharded differently, or one that is not sharded, does not. Small tables that every
shard needs, like the list of venues, are usually **copied to every shard** rather than sharded, so
that joins to them stay local.
