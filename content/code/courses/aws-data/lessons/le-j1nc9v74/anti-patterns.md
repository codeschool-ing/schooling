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
an access pattern of its own**, append and take, and it has stores built for it: a stream such as
Kinesis when the order matters and several consumers read, a queue service when each message goes to
one worker. The database keeps the record of what was done, not the list of what is waiting.

## DynamoDB without access patterns

**The pattern is a table designed like a relational one**, with an id as its key, and the queries
discovered afterwards. The first query that is not by id becomes a `Scan` with a filter, which reads,
and bills, every item in the table to return a handful, as lesson 10 showed. The next becomes a
global secondary index added in a hurry, and the one after that another. Or the key is a value with
few distinct values, a status or a date, and every write lands on the same partition, which throttles
while the rest of the table sits idle. **DynamoDB is cheap and fast for the queries it was designed
for, and nothing else**; a team that cannot write its queries down before creating the table is on
the relational branch of the tree, whatever it hoped.

## A warehouse as the store of an application

**The pattern is an application writing its rows straight into Redshift**, one insert or update at a
time, because the analysts are there and it saves a pipeline. Redshift is built to scan columns across
billions of rows, and a single-row write is the opposite: each one is a small commit to columnar
storage, and many of them queue behind each other. Its primary and foreign keys are declared and not
enforced, so the duplicates an application would have been stopped from writing are written. **The
application belongs on a database that enforces its rules and answers in milliseconds**, and the
warehouse is loaded from it in batches, through a pipeline such as lesson 26's.

## Athena over millions of tiny files

**The pattern is a producer writing one small file per event**, or per second, into the lake, and
Athena querying the folder. Every file is at least one request to S3 and a fixed amount of work for
the engine to open, so a day of small files is a query that spends its time opening files rather
than reading data. The request bill is the visible part: at 0.00056 per 1,000 `GET` requests, a
query that opens two million objects pays 2,000,000 × 0.00056 ÷ 1,000 = 1.12 in requests alone, every
time it runs, before a byte has been scanned. And it runs slowly enough that people notice. **Write
fewer, larger files**: lesson 19 is about why, Firehose buffers events into them, and a compaction job
can merge what was written small.

## What the four have in common

**Each one asks a store to serve an access pattern it was not built for, because it was already
there.** The cure is never a bigger machine; it is the first question of this lesson, asked of the
workload instead of the inventory.
