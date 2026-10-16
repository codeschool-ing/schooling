---
title: Write the choice down
version: 1
---

A database choice outlives the people who made it. Three years later somebody asks why the shop
runs Redis next to Postgres, and **the answer is either a page somebody wrote at the time or a guess**.
A decision record is that page: short, dated, written before the choice is acted on, and kept with
the code. Lesson 20 of `architecture` and lesson 17 of `tech-strategy` teach the format in
general; this section gives it the questions this course has been asking.

## The template

Copy it into a file next to the code and fill one row per operation that matters, not per table.
The first three columns are lesson 1's per-operation table; the rest are what the following
lessons added:

| question | where it came from |
|---|---|
| the operation, in the business's words | lesson 1 |
| what happens if two copies disagree for a moment | lesson 1 |
| what happens if the operation is refused | lesson 1 |
| so: consistency or availability, and how much latency it can pay | lessons 1 and 5 |
| the access pattern: by key, by range, whole aggregate, ad hoc | lessons 3 and this lesson |
| the volume today, and the volume that would change the answer | lesson 16 |
| the family, then the product, its version and its licence | lessons 2 and 21 |
| self-hosted or managed, and by whom | lesson 21 |
| how it is backed up, and when the restore was last drilled | lessons 11 and 13 |
| the signals that page somebody | lesson 20 |
| what leaving would cost | lesson 21 |

Below the table, four short paragraphs: **the decision**, **the alternatives considered** and why
they lost, **the consequences** you accept, and **what would make you revisit it**, as a number
or an event rather than a feeling.

## The shop's, filled in

| operation | disagree for a moment | refused | so | pattern | decision |
|---|---|---|---|---|---|
| take the last monitor out of stock | sold twice | error, retry | consistency | several rows in one transaction | Postgres |
| charge the card for an order | charged twice | the order waits | consistency | one transaction with the order | Postgres |
| store the order with its items | a lost order | error, retry | consistency | whole aggregate, joined to stock and payments | Postgres, items as rows; a `jsonb` column for the gift options |
| count a page view | a few views behind | a lost view | availability, and low latency | one hot key, thousands of increments | Redis, beside Postgres |
| keep a logged-in session | logged out once | logged out | availability | by key, with expiry | Redis, beside Postgres |

**Decision.** Postgres holds orders, stock, payments and customers. Redis holds page counters and
sessions, data the shop can lose with a login and a gap in a graph. The stock figure shown on
product pages is copied into Redis through an outbox, never by a dual write.

**Alternatives considered.** MongoDB for the orders: the order is an aggregate, but it is changed in
the same transaction as stock and payment, and the shop's reports join it to everything. Cassandra:
the write volume is thousands a day, not thousands a second, and the questions are still changing.

**Consequences accepted.** Two databases to back up, drill and watch; two skills on call; an outbox
table and a relay to run.

**Revisit when** writes outgrow the largest primary that can be bought, the shop opens a second
region that must accept orders while cut off from the first, or Redis stops being cheaper than the
`UNLOGGED` table of the previous sections. Not before.

That last line is the honest answer the course has been building to: **for most of the shop, it
should stay relational**, and the rest of what this course taught is how to recognise the day it
should not, and how to run the other database well when that day comes.
