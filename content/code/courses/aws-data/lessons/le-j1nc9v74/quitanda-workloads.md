---
title: Quitanda's workloads, each with its store
version: 1
---

**Quitanda runs on several stores, and every one of them is there because a workload asked for
it.** This section goes through the workloads the course has met, asks each the six questions, and
gives the answer with the reason. Where two stores were close, it says which question decided.

## Checkout and orders: Aurora PostgreSQL

**An order is a transaction across several tables**: the order, its lines, the stock of each product,
the payment record. All of it succeeds or none of it does, and the customer who has just paid expects
to see the order on the next screen, so the first and third questions both point at a relational
database. The load is a few hundred orders an hour at the evening peak, which one writer handles
with room to spare. Lesson 8 made the case for Aurora over plain RDS on its storage layer and its
failover; with a quiet night and a busy evening, Aurora Serverless v2 is the version whose price
follows the curve. **Decided by: the access pattern and consistency.**

## Carts and sessions: DynamoDB, with a time to live

**A cart is read and written by one key, the customer, many times in a few minutes, and then
abandoned.** Nothing joins it to anything until it becomes an order, at which point it is copied into
Aurora. That is DynamoDB's branch exactly: one key, single-digit milliseconds, a load that spikes on
Friday evenings, and an expiry attribute that deletes abandoned carts on their own after a day, at no
cost in writes. Putting carts in Aurora would work, and it would fill the database the business runs
on with rows nobody keeps. **Decided by: the access pattern and scale.**

## The product catalogue page: ElastiCache in front of Aurora

**The same few thousand products are read millions of times a day and changed a few times.** The
store of record stays Aurora, where the products live with their prices and stock; a Valkey cache in
front of it answers the page in under a millisecond and takes the reads off the database. When a
price changes, the application deletes the cached entry, and the next read fills it again from
Aurora. **Decided by: latency, with the store of record unchanged.**

## The nightly exports and the click stream: S3, through Kinesis and Firehose

**Files that have to be kept for years, read in bulk by jobs, never updated row by row**, are S3's,
and lessons 1 to 5 built the bucket layout, the classes and the life cycle for them. The click stream
of the app is events that never stop: lesson 20 put them in a Kinesis stream for the consumers that
need them within seconds, and lesson 21 had Firehose deliver them into the lake without a line of
code. The stream is how they travel; S3 is where they are stored. **Decided by: the access
pattern, and the price of keeping years of data.**

## The legal archive: S3 Glacier Deep Archive, under Object Lock

**Tax records that must be kept for years, read almost never and never changed**, go to the coldest
class, with a retention period nobody can shorten, as lessons 2 and 3 set up. At 0.00320 a GB-month
it is the cheapest storage in the sheet, and its retrieval takes hours, which is acceptable for a
document an auditor asks for once. **Decided by: price, once the access pattern allowed it.**

## Analysts' questions: Athena, then Redshift when the questions become a dashboard

**The questions are scans and aggregations over months of orders and clicks**, which is the
analytical branch, and the choice inside it is between paying per question and paying per hour.
Athena charges 9.00 a terabyte scanned and nothing between queries; Redshift Serverless charges
0.59760 per RPU-hour while queries run. A question scanning 20 GB of Parquet costs 0.02 × 9.00 = 0.18
on Athena. Five hundred of them a day, the load of a dashboard refreshed by forty analysts, scan
10 TB and cost 90.00 a day. The same day on a Redshift Serverless workgroup at 8 RPUs, busy for ten
hours, costs 8 × 0.59760 × 10 = 47.81, with the data loaded and sorted for those queries. **Occasional
questions belong to Athena; a dashboard that asks the same questions all day belongs to Redshift.**
**Decided by: price, at the volume the access pattern produces.**

## One rule over all of them

**One store of record per fact, and every other copy derived from it.** The order lives in Aurora;
the lake's copy came from DMS in lesson 26, the cache's copy from a read, the warehouse's from a load.
When two stores disagree, the store of record is right by definition, and a design that cannot say
which store that is for a given fact has not finished being designed.
