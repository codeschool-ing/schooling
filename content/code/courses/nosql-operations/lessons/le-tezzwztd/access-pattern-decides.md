---
title: The access pattern decides, not the brand
version: 1
---

The question usually arrives as "should we use MongoDB or Cassandra?", which is a question about
brands, and it is answered with benchmarks and opinions. **The question that has an answer is
about the operations**: what the application reads and writes, how often, in what shape, and what it
costs if two copies disagree. Lesson 1 asked the last part per operation, lesson 3 listed the
queries before the tables, lesson 4 decided what to write twice, and lesson 5 said what an
application must tolerate when copies lag. This section turns those into one table.

## From the pattern to the family

Read it from the left. Find the row that describes an operation of yours, not your whole system:

| the access pattern | what it needs | the family that fits | where this course showed it |
|---|---|---|---|
| read and write one entity by its key, nothing else | a fast lookup, no joins | key-value | Redis strings and hashes, lesson 12 |
| the unit read and written is a whole aggregate whose shape varies: an order with its items, a product with its attributes | the aggregate in one place, a schema that bends | document | MongoDB, lessons 6 to 8 |
| append a very high volume of writes, read them back by a known key and a range | writes spread over many machines, queries known in advance | wide column | Cassandra, lesson 16 |
| one table per query, written twice on purpose | denormalisation the database will not keep consistent for you | wide column or document | lessons 3 and 4 |
| a counter, a ranking, a rate limit, a session, a queue, read and written at memory speed | data structures in memory, with expiry | key-value with structures | Redis, lessons 12 and 14 |
| relationships followed many hops deep: who knows whom, which part is in which assembly | traversal | graph | named in lesson 2 |
| measurements over time, queried by time window and aggregated | compression and retention by time | time series | named in lesson 2 |
| several entities changed together, or questions nobody has asked yet | transactions, joins, ad-hoc queries | **relational** | `sql-databases`, and the next section |

**The last row is the one most systems are made of.** An online shop has customers, products,
orders, stock and payments, changed together in transactions and queried in ways the business will
invent next year. Lesson 1's table said that taking the last monitor out of stock and charging the
card need consistency; lesson 5 showed what an application has to do to live without it. A
relational database gives both operations that consistency without the application doing anything.

## Two warnings the table cannot carry

**Patterns, not systems.** The table classifies operations, and one application has many. The shop
whose orders belong in Postgres may still count page views in Redis. The decision is per operation,
and the cost of acting on it, a second database, is the subject of the section after next.

**The table describes the pattern you have, not the one you might.** "We will have a billion events a
day" justifies Cassandra on the day it is true, and before that it costs everything lesson 16 asked
of you: every query written first, every new question a new table. A pattern that is a forecast
goes in the decision record as a forecast, with the number that would make it real.
