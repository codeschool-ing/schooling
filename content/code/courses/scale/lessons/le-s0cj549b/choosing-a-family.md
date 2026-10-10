---
title: Choosing, and the cost of one more database
version: 1
---

Each family answers one of the box office's access patterns better than PostgreSQL does, and the
obvious conclusion is to use five databases. **That conclusion is usually wrong**, and the reasons
are operational rather than technical.

## The tax on every database

A database in production is more than the data in it. Each one needs:

- **backups**, and a restore that someone has actually rehearsed;
- **monitoring**: its own metrics, its own ways of being slow, its own alerts;
- **upgrades**, on its own schedule, with its own breaking changes;
- **someone who understands its failure modes** at three in the morning;
- **a way to keep its copy of the data in step** with every other database that holds a copy.

The last one is the worst. A show's name in PostgreSQL, in a MongoDB document and in a Neo4j node is
three places to update, with no transaction across them, so for some window they disagree. The
consistency problems of lesson 3, between replicas of one database, come back between databases,
with no replication protocol to solve them.

## A habit for deciding

1. **Write the access patterns down**, as in section 03, with how often and how fast.
2. **Ask whether the database you already run can serve each one well enough.** PostgreSQL has
   `jsonb` for documents, partitions for time-ordered data, recursive queries for short graph
   walks. "Well enough" is measured, as in lesson 1, not assumed.
3. **Add a database for a pattern only when the measurement says so**, and when the pattern is
   central enough to pay the tax above.
4. **Decide which database is the source of truth** for each fact, and treat every other copy as
   derived from it and rebuildable.

## Where specialised stores usually earn their place

| pattern | usually worth a separate store when | otherwise |
|---|---|---|
| key-value | latency in microseconds, expiry, or volume beyond the main database | a table with an expiry column |
| document | the schema genuinely varies per record, or the data is huge and read whole | `jsonb` in PostgreSQL |
| wide column | writes in the hundreds of thousands per second across many servers | partitioned tables |
| graph | deep or variable-depth traversals are the product | recursive SQL for shallow ones |
| time series | metrics and events in large volumes with retention and downsampling | partitioned tables, or the monitoring system you already run |

The shape this course arrives at for the box office is the most common one of all: PostgreSQL as
the truth for shows and tickets, and Redis beside it for holds and counters, which lesson 9 adds.
**One relational database and one key-value store.** Lesson 5 runs the other four so that their trade-offs are something you have seen rather
than something you read; it does not argue that you need them.
