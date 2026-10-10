---
title: Write the queries down first
version: 1
---

Modelling by access pattern starts with a table that has no data in it: **the list of every
question the application will ask, before any collection, key or table exists.** It feels
backwards, and it is the step that decides everything after it.

## The shop's access patterns

An access pattern is a question in the form the application asks it: what it already knows when it
asks, what it wants back, in what order, and how often. These are the shop's, with the rates the
team expects in the first months. **The rates are estimates**, which is all anybody has before
launch, and they are good enough to rank the rows:

| # | the question | the application already knows | it wants back | expected rate |
|---|---|---|---|---|
| 1 | show a product page | the product code | name, price, stock, photos | 2,000 a minute |
| 2 | show and change the basket | who the customer is | the products in it, with quantities | 300 a minute |
| 3 | show an order | the order number | the whole order, lines included | 200 a minute |
| 4 | "my orders" | who the customer is | their orders, **newest first**, ten at a time | 50 a minute |
| 5 | best sellers this week | nothing | the top ten products by units sold | once a minute, by a job |
| 6 | orders over 500 to review for fraud | nothing | the orders above the amount, oldest first | a few times a day |

## What each column decides

**"Already knows" is the key.** Rows 1 to 4 start from a value the application has in hand: a
product code from the URL, a customer from the session, an order number from a link. Each can be one
lookup by key, which all three products are fast at, if the data is stored under that key.

**"Wants back" is the unit.** Row 3 wants the order and its lines together, which argues for keeping
them together. Row 1 wants a product without its reviews, which argues against putting thousands of
reviews inside the product.

**"Newest first" is an order the storage can keep.** If rows are stored sorted the way row 4 reads
them, the query is "the first ten", and no sorting happens at read time.

**The rate is how much to pay for it.** A question asked 2,000 times a minute deserves a structure
of its own, even a duplicate one. A question asked a few times a day can afford to be slow.

## The rows with nothing to start from

Rows 5 and 6 know nothing when they start. In a relational database they are ordinary queries; in a
store that answers by key, **a question that starts from nothing is a scan**, or a structure built
in advance to hold the answer. Best sellers can be a sorted set that every sale increments, or a
result a job writes once a minute. The fraud review, at a few times a day, can be a pipeline over the
orders, lesson 8, or a query against a copy of the data in a warehouse built for questions nobody
listed.

## The list is a contract

The design that follows answers these six questions well and others badly. A seventh question next
year is a new table, a new key or a new index, **plus filling it with every record written before
it existed**, which is lesson 4's subject. That is the price of the approach, and the reason to spend
an afternoon on this table before writing anything else: changing it on paper costs nothing.

The next three sections take rows 3, 4 and 2 to MongoDB, Cassandra and Redis.
