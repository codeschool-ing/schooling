---
title: Quitanda's workloads, each with its store
version: 1
---

**Quitanda runs on several stores, and each is there because a workload asked for it.** Each heading
below names the workload and its store, and each paragraph ends with the question from the first
section of this lesson that decided it.

## Checkout and orders: Azure SQL Database

**An order is a transaction across several tables**: the order, its lines, the stock of each product,
the payment record. Either all of them change or none does, and the shop reads them back joined. That
is the relational branch, and Azure SQL Database, lesson 8, is its managed default. The General
Purpose tier is enough at Quitanda's size; Business Critical buys faster failover and a readable
replica, worth it the day a minute of checkout downtime costs more than the difference.
**Decided by: the access pattern, and consistency.**

## Carts and sessions: Cosmos DB

**A cart is read and written by one key, the customer, many times in a few minutes, and then
abandoned or turned into an order.** One item by a key, at the evening peak's scale, with no joins:
Cosmos DB, lesson 11, partitioned by the customer, with a time to live so that abandoned carts delete
themselves. Session consistency, the default of lesson 12, is exactly the promise a cart needs: a
customer always sees their own last change. **Decided by: the access pattern, and scale.**

## The product page: Azure Cache for Redis in front of SQL

**The same few thousand products are read millions of times a day and changed a few times.** The
store of record stays the SQL database; the cache of lesson 15 answers the reads, with a time to live
short enough that a price change shows within minutes. **Decided by: latency.**

## The nightly exports, the click stream and the lake: Blob Storage

**Files kept for years, read in bulk by jobs and never updated row by row**, are Blob Storage's, on an
account with the hierarchical namespace. The exports land in the hot tier and a life-cycle rule moves
them to cool and archive, lessons 4 and 5. The clicks arrive through Event Hubs, lesson 22, and
Capture writes them as Avro into the same lake, where a pipeline turns them into Delta tables,
lesson 18. **Decided by: the access pattern, and price.**

## The fraud check: Event Hubs and a reader of its own

**Seconds matter, and the pattern of interest spans a customer's last ten minutes.** The fraud check
reads `clicks` through its own consumer group and keeps a sliding window per customer, which is a
Stream Analytics job of lesson 23 or a program of Quitanda's; what it flags is written to Cosmos DB
for the shop to read by the customer's id, idempotently, as lesson 24 required.
**Decided by: latency, and the access pattern.**

## The analysts' questions: the lake, queried in place, then a warehouse

**The questions are scans and aggregates over months of orders and clicks**, the warehouse branch.
While they are occasional, a serverless SQL pool or a Fabric lakehouse reads the Delta files in place
and charges by what it reads, lessons 16 and 17. When the same questions become a dashboard refreshed
every hour by thirty people, a capacity bought by the hour becomes cheaper than paying per query, and
the decision is revisited. **Decided by: price, at the volume the access pattern produces.**

## One rule over all of them

**One store of record per fact, and every other copy derived from it.** The order lives in Azure SQL
Database; the lake's copy, the cache's copy and the analysts' tables are derived from it and can be
rebuilt from it. When two stores both accept writes for the same fact, the day they disagree there
is no way to say which one is right. Purview's lineage, lesson 25, is how a team proves, months
later, which copy came from where.
