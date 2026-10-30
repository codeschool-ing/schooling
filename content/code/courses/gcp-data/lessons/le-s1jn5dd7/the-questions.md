---
title: Six questions, asked in order
version: 1
---

**The wrong way to choose a store is to start from the store.** "We use PostgreSQL", "BigQuery
scales", "put it in Firestore" are answers that arrived before the question, and each of them is
right for some workload and expensive for the rest. Every store in this course is good at one shape
of reading and writing and bad at others, so the choice starts from the shape of the workload and
lets the stores fall out of it.

**Six questions, in this order, because each one narrows what the next has to decide between.**

**1. What is the access pattern?** How is the data written, and how is it read: one document by its
id, a range of rows under one key, rows joined across tables inside a transaction, whole files read
from start to end, a scan of millions of rows to compute a total. This is the question that decides
most choices on its own, and the one most often skipped. Bigtable in lesson 11 was designed by
writing its reads down before its row key, and Firestore in lesson 10 answers no query without an
index for it; that discipline is the first question asked of every store.

**2. How fast does an answer have to come?** A shop's checkout waits for milliseconds; a nightly
report waits for minutes and nobody minds. Below a millisecond, the answer is a cache. Within a few
milliseconds at any scale, a document or wide-column store, or a relational database with the
right index. Seconds are fine for BigQuery, and nowhere near fine for a customer pressing a button.

**3. What consistency does the reader need?** Must a read see the write that has just happened, or
may it be a moment behind? A customer who has just paid expects to see the order; a dashboard of
yesterday's sales does not care about the last second. Transactions that change several rows at
once and must all succeed or all fail are relational territory, which Spanner extends across
regions at a price. A read replica, a cache and a warehouse loaded overnight are all, by design,
behind the source.

**4. How big, and how fast does it grow?** Gigabytes or terabytes, a hundred requests a second or a
hundred thousand, and above all whether the load is steady or spiky. Cloud SQL grows by moving to a
bigger machine until there is none bigger; Spanner, Bigtable and Firestore grow by spreading, by
nodes, processing units or nothing you see at all; BigQuery grows by slots, which are somebody
else's machines for the length of a query.

**5. Who operates it?** Every store has work that does not go away: sizes to choose, versions to
upgrade, indexes to maintain, vacuum to watch, capacity to adjust. The managed services take a lot
of it away and none takes all of it. A team of three should count the stores it already runs before
adding one.

**6. What does it cost, at this workload?** Last, because a price only means something once the
workload is known: a store that is cheap per operation can be dear per month, and one that costs
money while idle can be cheap per operation when it is busy. The pricing pages answer this question
only after the first five have said what to multiply.

## Why the order matters

**Asked first, the price question chooses badly.** BigQuery's on-demand price per tebibyte looks
cheaper than a database that costs money every hour, and it is, for a question asked once a day over
the warehouse. For a customer's "my orders" screen asked a hundred thousand times a day, it is a
disaster in both latency and cost, and the section after next does that arithmetic. The access
pattern had already ruled BigQuery out before the price was read; reading the price first would have
ruled it in.

**And the questions are asked per workload, not per company.** Quitanda is not "a Firestore shop" or
"a PostgreSQL shop". Its checkout, its carts, its click stream, its archive and its analysts' reports
are five workloads with five different answers to the first question, and the next two sections give
each of them its store.
