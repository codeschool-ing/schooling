---
title: When the other database wins, honestly
version: 1
---

A course that ends by recommending Postgres could be read as saying the last twenty-one lessons were
for nothing. **They were not, because there are cases where each of the three is the better
answer**, and each was shown working in this course. What follows is that list, each case tied to
the lesson that demonstrated it, and each with the sign that you are in it.

## Redis, beside the main database

Redis wins as **a second database for the operations that need memory speed and data structures**,
with the main database still holding the truth:

| the case | why Redis | lesson |
|---|---|---|
| counters, at thousands of increments a second on one key | `INCR` is atomic and in memory; a row updated that often is a lock everybody queues on | 12 |
| rate limits | a counter with an expiry is the whole algorithm | 12, 14 |
| sessions | read on every request, small, expendable with a login as the fallback | 14 |
| leaderboards | a sorted set keeps the ranking ordered as scores change | 12 |
| queues and event streams between services | lists, and streams with consumer groups | 12 |
| a cache in front of the database | eviction policies made for it | 14 |

The sign you are in this case: **the operation is small, hot and forgivable**. Lesson 13 showed
what Redis keeps after a crash with each kind of persistence, and lesson 15 lost an acknowledged write
on purpose. An operation that can afford those losses belongs here; one that cannot belongs in the
database that can.

## Cassandra, when writes outgrow one machine or one region

Cassandra wins on **a very high, steady volume of writes, read back by key and time, in more than
one datacentre**: device telemetry, events, messages, an audit trail at a scale where one primary
cannot take the writes.

- **Write volume**: every node takes writes, and adding nodes adds capacity (lesson 16). This is the
  first item of the previous section's list of things Postgres does not do as well.
- **Time series by key**: a partition per device and day, clustered by time, is the shape lesson 16
  wrote its queries for.
- **Several datacentres writing at once**: `LOCAL_QUORUM` in each, with replication between them
  (lesson 17). The second item of that list.

The sign: **you can write down every query before the first table, and the list will not change
often**. Lessons 16 and 18 showed what a new query and a delete-heavy pattern cost; a system whose
questions are still being discovered pays that price every month.

## MongoDB, when the document is the unit

MongoDB wins when **the thing read and written is a whole document, its shape varies between
documents, and transactions across documents are the exception**: a product catalogue where a
monitor and a cable have different attributes, content with nested sections, a configuration per
customer.

- The document is read whole and written whole, so one operation touches one place (lesson 6).
- Indexes, aggregation and a replica set are all there when the shape is settled enough to need
  them (lessons 7 to 9), and sharding when the size needs it (lesson 10).

The sign: **you would otherwise store a `jsonb` column and query almost nothing else**. The
previous section showed Postgres doing that well, so the case for MongoDB is strongest when the
documents are the whole application and their scale or their team's familiarity with MongoDB tips
it, not when they are one table among twenty.

## And the case for staying

If none of those signs is clearly true, **the honest answer is the relational database you already
operate**: one backup, one failover, one set of skills on call, transactions across everything, and
the questions of next year answerable with a query nobody planned. That is not a lack of ambition.
It is what lesson 1's per-operation table says for most of the operations of most applications.
