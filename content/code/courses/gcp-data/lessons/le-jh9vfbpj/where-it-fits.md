---
title: Between Cloud SQL and Spanner, and AlloyDB Omni
version: 1
---

**Google sells three answers to "I need a relational database", and they differ in what grows when the
load does.** Cloud SQL grows by moving to a bigger machine, and copies its data for every replica.
AlloyDB grows reads by adding nodes that share one storage layer, and writes by moving the primary to
a bigger machine. Spanner, lesson 9, grows writes as well, by spreading the data over more machines.
Each step to the right buys a kind of growth the one before it cannot have, and charges for it.

**The wrong idea is that they are three sizes of one product**, so that a database outgrows Cloud SQL
into AlloyDB and AlloyDB into Spanner. The first step is close to true: AlloyDB is PostgreSQL, the
application changes a connection string, and Google ships a command for the move, which this
laptop's command line knows:

```
ana@laptop:~/gcp$ gcloud alloydb clusters migrate-cloud-sql --help | sed -n '/^DESCRIPTION/,/^EXAMPLES/p'
DESCRIPTION
    Migrate Cloud SQL instance to an AlloyDB cluster using an existing Cloud
    SQL backup.

EXAMPLES
```

**The second step is not a move, it is a new design.** Spanner speaks SQL, with a PostgreSQL dialect
among its two, but it is not PostgreSQL: its primary keys decide where rows are stored, it has its
own way of keeping a parent's rows beside its children's, and the extensions and functions of a
PostgreSQL server are mostly not there. Lesson 9 is about exactly those differences. A database that
might need Spanner one day is designed for Spanner from the start, or rebuilt when the day comes.

## Side by side

| | Cloud SQL for PostgreSQL | AlloyDB for PostgreSQL | Spanner |
|---|---|---|---|
| the engine | PostgreSQL | PostgreSQL, with Google's storage and columnar engine | Spanner's own, GoogleSQL or a PostgreSQL dialect |
| writes go to | one primary | one primary | every node, by key range |
| reads scale by | read replicas, each with its own copy | read pool nodes, no copy | adding nodes |
| storage | a disk you size, per instance | used GiB, once per cluster | used GiB, once per instance |
| the regions | one, plus cross-region replicas | one, plus secondary clusters | one, two or several, as one database |
| what changes to move in | little | a connection string | the schema and the queries |

**The middle column is the one this lesson is about**, and its place is the last row as much as any
other. AlloyDB is for the PostgreSQL database that has outgrown what a single Cloud SQL machine and its
replicas do well, usually on reads, on mixed analytical load, or on the time a failover or a new
replica takes, and that is still a database with one writer. Quitanda's orders database is that
shape: the shop writes a few hundred orders a minute at the evening peak, which one machine absorbs
easily, and reads many times that, from the app, from the catalogue and from the analysts.

**A cross-region copy exists in all three, and means something different in each.** Cloud SQL's is a
replica in another region, lesson 7's. AlloyDB's is a **secondary cluster**, created with `gcloud
alloydb clusters create-secondary`, which receives the primary cluster's changes asynchronously and
can be promoted if the primary region is lost. Spanner's multi-region configurations are one
database whose writes are committed in several regions at once, which is a different promise and, as
lesson 9 prices it, a different bill.

## What does not decide it

**Not the SQL.** All three answer `SELECT … GROUP BY …`, and the analysts' report runs on any of them.
The difference is how much each one reads to answer it, which the previous section measured.

**Not the size of the data, on its own.** A Cloud SQL disk goes to tens of terabytes, more than
Quitanda will ever hold in an orders table. The question is what the load does to one machine, not
how many bytes sit behind it.

**And not the name on the price list.** The last section of this lesson prices the same database
both ways, and AlloyDB comes out more expensive at São Paulo's list prices for the shape Quitanda
needs. It can still be the right choice; the bill says what the choice costs, not whether it is
right.

## AlloyDB Omni, the one you can download

**AlloyDB Omni is AlloyDB's engine packaged to run on your own machines**: a container image Google
publishes for Linux, Docker and Kubernetes, with the columnar engine inside it, for a data centre, a
laptop or another cloud. It is a separate product from the managed service, with its own editions
and licence terms, and Google's AlloyDB Omni documentation is where those are described. The
managed pricing page read for this lesson does not price it, so this lesson gives no number for it.

**This lab does not run it**, and the reason is worth stating: it is the engine without the part
this lesson is about. Omni stores its data on the disks of the machine it runs on, so the shared
regional storage layer, the read pools that need no copy and the failover that moves nothing are not
in it. What Omni is good for is exactly what this lesson did with plain PostgreSQL, and
better: trying the columnar engine on your own data, on your own machine, before paying for a cluster.
If you do run it, Google's quickstart for AlloyDB Omni is the place to start, and its version will
not be the one any transcript here shows.
