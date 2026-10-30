---
title: Four ways to choose wrong, and what each costs
version: 1
---

**Each of these works on the first day**, which is why they are common. The store answers, the
feature ships, and the cost arrives later, as a bill, a slow page or an outage, by which time the
data is in the wrong place and moving it is a project.

## A relational database as a queue

**The pattern is a `jobs` table**: producers insert rows, workers poll it every second with
`SELECT … WHERE status = 'pending' … FOR UPDATE SKIP LOCKED`, and mark each row done. It works, and
it fails along every axis of the six questions at once. Every poll is a query on the database the
business runs on, whether or not there is work. Every finished job is an update, and in PostgreSQL
an update leaves a dead row behind for vacuum, so a busy queue table bloats faster than vacuum cleans
it and the polls get slower as it grows. Workers compete for locks on the same few rows. **A queue is
an access pattern of its own**, append and take, and it has a store built for it: Pub/Sub, with a
subscription per consumer, an acknowledgement per message and a dead-letter topic for the ones that
keep failing, as lessons 19 and 20 showed. The database keeps the record of what was done, not the
list of what is waiting.

## A key-value store without access patterns

**The pattern is a Bigtable table whose row key is the timestamp**, because events arrive in time
order and "the newest" is the obvious question. Every write lands at the end of the key space, on
the one node that holds it, which throttles while the rest of the cluster sits idle; lesson 11 drew
that hotspot. Firestore has the same failure in a gentler form: a collection designed like a
relational table, with the queries discovered afterwards, meets its first query that needs a
composite index nobody created, and then the next, each one an index that costs storage and a write
for every document. **A store designed around its keys is cheap and fast for the queries it was
designed for, and nothing else**; a team that cannot write its reads down before choosing the key is
on the relational branch of the tree, whatever it hoped.

## A warehouse as the store of an application

**The pattern is an application writing its rows straight into BigQuery**, one `INSERT` or `UPDATE`
at a time, because the analysts are there and it saves a pipeline. BigQuery is built to scan columns
across billions of rows, and a single-row change is the opposite: each DML statement is a job, with
its own start-up time, that rewrites storage underneath, and the quotas on concurrent DML statements
per table make a busy application queue behind itself. Its primary and foreign keys are declared and
not enforced, so the duplicates an application would have been stopped from writing are written.
**The application belongs on a database that enforces its rules and answers in milliseconds**, and
the warehouse is fed from it, through a change stream such as lesson 25's.

## A query that reads everything, every time

**The pattern is a dashboard built on `SELECT *` over a table with no partition filter**, refreshed
every few minutes. Each refresh is billed for every byte of every column it names, across every day
the table holds, because nothing told BigQuery it could read less: lessons 15 and 16 measured that
difference. The same failure on an external table is millions of small files in Cloud Storage, where
every file opened is a Class B operation and a fixed amount of work before a byte is read. **Name the
columns, filter on the partition, and keep files large**; and set a limit on the bytes a query may
bill, so that the mistake costs an error rather than an invoice.

## What the four have in common

**Each one asks a store to serve an access pattern it was not built for, because it was already
there.** The cure is never a bigger machine; it is the first question of this lesson, asked of the
workload instead of the inventory.
