---
title: The access patterns come before the table
version: 1
---

**In a relational database you model the data and the questions come later; in DynamoDB you list
the questions first.** That is the inversion people resist, because normalising entities is a skill
they already have and it feels like design. Here it is not enough. A table whose keys were chosen
before anyone wrote down how it would be read answers one question well, by luck, and answers the
rest with a scan of every item.

**An access pattern is one question, written with its inputs and its expected size.** Not "orders",
but "the orders of one customer in a date range, newest first, a few dozen at most". The inputs say
what the key has to be built from; the size says whether one read is enough; the order says what the
sort key has to sort by. Quitanda's app and back office need five:

| | the question | given | returns |
|---|---|---|---|
| A1 | a customer's profile | the customer id | one item |
| A2 | a customer's orders in a date range, with their lines | the id and two dates | a few dozen items |
| A3 | one order and its lines | the customer id, the date and the order id | up to ten items |
| A4 | a customer's latest order | the customer id | one order |
| A5 | every order placed on one day, across customers | a date | hundreds of items |

**Each pattern becomes a key condition, or it becomes a problem.** A1 is a `get-item` on
`CUSTOMER#<id>` and `PROFILE`. A2 is a `query` on the same partition key with the sort key between two
prefixes, which works only if the sort key starts with the date. A3 is the same partition key with
the sort key beginning with one order's prefix, which works only if the lines sort directly under
their order. A4 is A2 read backwards with a limit of one, and the next sections show that the design
below makes it subtly wrong, which is exactly the kind of thing writing patterns down finds early.

**A5 is the one this table cannot answer.** The customer is the partition key, and a question that
does not start from a customer cannot name a partition, so the only way to answer it from this table
is a scan. It is left in the list on purpose. Lesson 10 adds the index that answers it, and prices
what the scan would cost instead; a pattern the table does not serve is a decision to make in
writing, not a surprise found in production.

## What a pattern does not care about

**A pattern does not mention entities, tables or joins.** "The order and its lines" is one question,
even though a relational model calls it two tables and a join. That is what makes it possible to
serve with one read: the lines are stored where the order is, sorted next to it, and the query that
returns one returns the other. The price is paid elsewhere. Data is duplicated where two patterns
need it in two shapes, and a question nobody listed has nothing to stand on.

**Writing the list is also how you find out DynamoDB is the wrong store.** If the questions are
ad hoc, change every week, or aggregate across everything, "the revenue per district this month",
a store that is read by key is fighting the workload. Those belong in the warehouse and the lake of
lessons 14 to 19, often fed from this table, and lesson 12 shows the stream that does the feeding.
