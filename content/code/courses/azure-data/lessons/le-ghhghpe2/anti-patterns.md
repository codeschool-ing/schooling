---
title: Ways to choose wrong that work on the first day
version: 1
---

**Each of these works on the first day**, which is why they are common. The store answers, the tests
pass, the demo is fine. The failure arrives with volume or with time, when changing the store costs a
migration rather than a decision.

## A relational database as a queue

**The pattern is a `jobs` table**: producers insert rows, workers poll it every second for the oldest
unclaimed row and mark it taken. It works with one worker and a few jobs a minute. With ten workers,
they fight over the same rows with locks, the table grows with rows nobody deletes, and the polling
alone keeps the database busy when there is no work. Event Hubs, lesson 22, or a queue built for the
job, Azure Storage queues or Service Bus, delivers to readers without polling and keeps the database
for what it is good at.

## Cosmos DB without its access patterns

**The pattern is a container designed like a relational table**, partitioned by a field nobody
queries on, or by a field with three values, and queried with filters on everything else. Every query
then crosses every partition and the request charge grows with the size of the data, which is lesson
11's whole subject. The fix is not a bigger throughput setting; it is a partition key chosen from the
queries, which usually means a new container and a migration.

## The lake as a database

**The pattern is an application reading single records out of Parquet or Delta files**, through a
serverless SQL pool or straight from Blob Storage, because the data was already there. The last
section priced it: every lookup reads far more than it returns and takes seconds. The lake is for
scans; a workload that reads by key needs a copy in a store built for keys.

## The cache as the store of record

**The pattern is data written only to Redis**, because it was fast and the database was "for later".
Azure Cache for Redis keeps data in memory, and lesson 15 showed what its tiers do and do not promise
about persistence; an eviction under memory pressure or a failover can remove keys, by design. A cache
holds copies of things that live somewhere else. A cart might tolerate being lost; an order cannot.

## One store for everything

**The pattern is choosing one store and fitting every workload into it**, so that the team runs one
thing. It is a reasonable instinct for a team of three, and the fifth question of this lesson takes it
seriously. It goes wrong when the store's branch is far from the workload's: the analysts' scans
running on the checkout database at noon, slowing every sale, or the click stream written row by row
into SQL. Fewer stores is a good aim; one store for workloads from four branches is a bill and an
outage waiting.

## A key that concentrates the load

**The pattern is a partition key chosen for convenience**: the date, so that all of today's writes go
to one partition; the store, with three stores; a constant. It works in testing, where the load is
small. In production, one partition takes everything while the others idle, and the throttling of
lesson 13 arrives while the account's total throughput looks generous. The same mistake on an event
hub, lesson 22, leaves partitions without readers' work and the busiest one behind. Choosing a key is
choosing how the load spreads, in every store that has one.
