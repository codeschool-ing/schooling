---
title: Quitanda's workloads, each with its store
version: 1
---

**Quitanda runs on several stores, and every one of them is there because a workload asked for
it.** This section goes through the workloads the course has met, asks each the six questions, and
gives the answer with the reason. Where two stores were close, it says which question decided.

## Checkout and orders: Cloud SQL for PostgreSQL, with high availability

**An order is a transaction across several tables**: the order, its lines, the stock of each product,
the payment record. All of it succeeds or none of it does, and the customer who has just paid expects
to see the order on the next screen, so the first and third questions both point at a relational
database. The load is a few hundred orders an hour at the evening peak, which one writer handles
with room to spare, and lesson 7 put a standby in a second zone of São Paulo behind it. AlloyDB, in
lesson 8, earns its price when the same database also has to answer heavy analytical queries, and
Quitanda sends those to BigQuery instead. **Decided by: the access pattern and consistency.**

## Spanner, considered and not chosen

**Spanner is the store for a relational workload that one writer cannot carry**, or one that must
accept writes in several regions at once with the same answer everywhere. Quitanda delivers in one
city. Its writes fit on one machine with years of growth left, and lesson 9 priced what Spanner charges for
its compute capacity whether or not it is used. Choosing it now would be paying for a
scale nobody has. **Decided by: scale, which did not ask for it.**

## Carts and sessions: Firestore, with a time-to-live policy

**A cart is read and written by one key, the customer, many times in a few minutes, and then
abandoned.** Nothing joins it to anything until it becomes an order, at which point it is copied into
Cloud SQL. That is Firestore's branch: one document by its id, milliseconds, a load that spikes on
Friday evenings with nothing to size, and a time-to-live policy that deletes abandoned carts on its
own after a day, billed as cheap TTL deletes. Putting carts in Cloud SQL would work, and it would
fill the database the business runs on with rows nobody keeps. **Decided by: the access pattern and
the spikes.**

## The product catalogue page: Memorystore in front of Cloud SQL

**The same few thousand products are read millions of times a day and changed a few times.** The
store of record stays Cloud SQL, where the products live with their prices and stock; a Memorystore
cache in front of it answers the page in under a millisecond and takes the reads off the database.
When a price changes, the application deletes the cached entry, and the next read fills it again
from Cloud SQL, which is lesson 12's cache-aside. **Decided by: latency, with the store of record
unchanged.**

## The app's click stream: Pub/Sub, then BigQuery, with Bigtable for the recent past

**Events that never stop**, a few hundred a second at the peak, go to a Pub/Sub topic, as lesson 19
set up, so that every consumer reads them at its own pace. Dataflow, in lessons 21 and 22, windows
them by event time and writes the aggregates to BigQuery and the raw events to Cloud Storage. The one
consumer that needs "this customer's last fifty clicks, now" reads them from Bigtable, keyed by the
customer and a reversed timestamp, the design of lesson 11. **Decided by: the access pattern, which is
three different patterns over the same events.**

## The nightly exports and the legal archive: Cloud Storage, by class

**Files that have to be kept for years, read in bulk by jobs, never updated row by row**, are Cloud
Storage's, and lessons 1 to 5 built the bucket layout, the classes and the life cycle for them. Tax
records that must be kept for years and read almost never go to the Archive class, under a locked
retention policy, as lessons 2 and 3 set up: the cheapest storage on the price list, with a minimum
of a year and a retrieval fee for each GiB read, which is acceptable for a document an auditor asks
for once. **Decided by: price, once the access pattern allowed it.**

## Analysts' questions: BigQuery, on demand until a dashboard asks all day

**The questions are scans and aggregations over months of orders and clicks**, which is the
analytical branch, and the choice inside it is between paying per byte and paying per slot. On
demand, a question scanning 20 GiB costs 20 ÷ 1,024 × $11.25, about 22 cents, after the free TiB of
the month, and nothing between questions. A dashboard refreshed by forty analysts all day is a
different workload, and lesson 14 found the volume at which a reservation of slots costs less than
the bytes. Lessons 15 and 16 are how the bytes are kept small either way. **Occasional questions
belong to on demand; a dashboard that asks the same questions all day belongs to slots.** **Decided
by: price, at the volume the access pattern produces.**

## One rule over all of them

**One store of record per fact, and every other copy derived from it.** The order lives in Cloud SQL;
BigQuery's copy came from Datastream in lesson 25, the cache's copy from a read, Firestore's cart
became an order by being copied. When two stores disagree, the store of record is right by
definition, and a design that cannot say which store that is for a given fact has not finished
being designed.
