---
title: Six questions, asked in order
version: 1
---

**The wrong way to choose a store is to start from the store.** "We use SQL Server", "Cosmos DB
scales", "put it in the lake" are answers that arrived before the question, and each is right for
some workload and expensive for the rest. Every store in this course is good at one shape of reading
and writing and poor at others, so the choice starts from the shape of the workload and lets the
stores fall out of it.

**Six questions, in this order, because each one narrows what the next has to decide between.**

**1. What is the access pattern?** How the data is written, and how it is read: one item by its key,
a handful of items under one key, rows joined across tables inside a transaction, whole files read
from start to end, a scan of millions of rows to compute a total, events that arrive for ever. This
question decides most choices on its own, and it is the one most often skipped. Lesson 11 designed a
Cosmos DB container by writing its queries down before choosing its partition key; that discipline
is the first question asked of every store.

**2. How fast does an answer have to come?** A checkout waits for milliseconds; a nightly report
waits for minutes and nobody minds. Under a millisecond, the answer is a cache, lesson 15. Within a
few milliseconds at any scale, a document store read by its key, or a relational database with the
right index. Seconds are fine for a serverless SQL query over the lake and nowhere near fine for a
customer pressing a button.

**3. What consistency does the reader need?** Must a read see the write that has just happened, or
may it be a moment behind? A customer who has just paid expects to see the order; a dashboard of
yesterday's sales does not care about the last second. Several rows changed together, all or none, is
a relational database's home ground, and Cosmos DB offers it within one logical partition. Lesson 12's
five levels are the vocabulary of this question, and a read replica, a cache and a lake are all, by
design, behind their source.

**4. How big, and how fast does it grow?** Gigabytes or terabytes, a hundred requests a second or a
hundred thousand, and above all whether the load is steady or spiky. A single relational database
grows by moving to more vCores until the tier has no more, with Hyperscale in lesson 8 as the way
past that. Cosmos DB and Blob Storage grow by spreading, with no machine to outgrow, as long as the
partition key of lesson 11 spreads; a warehouse grows by capacity bought in units.

**5. Who runs it?** Every store has work that does not go away: sizes to choose, indexes to maintain,
keys to rotate, a partition key that turned out hot, capacity to adjust after a peak. The managed
services take a lot of it away and none takes all of it. A team of three should count the stores it
already runs before adding one, because each new one is a new set of failures to learn at three in
the morning.

**6. What does it cost, at this workload?** Last, because a price only means something once the
workload is known: a store that is cheap per request can be dear per month, and one that costs
money every hour can be cheap per request when it is busy. The price sheet of lesson 1 answers this
question only after the first five have said what to multiply.

## Why the order matters

**Asked first, the price question chooses badly.** A serverless SQL pool billed per terabyte processed
looks cheaper than a database billed every hour, and it is, for a question asked once a day over the
lake. For a customer's "my orders" screen opened three million times a month it is slow and, as the
section after next computes, not cheap either. The access pattern had already ruled it out before the
price was read; reading the price first would have ruled it in.

**And the questions are asked per workload, not per company.** Quitanda is not "a SQL Server shop" or
"a Cosmos DB shop". Its checkout, its carts, its click stream, its archive and its analysts' reports
are workloads with different answers to the first question, and the next two sections give each of
them its store.
