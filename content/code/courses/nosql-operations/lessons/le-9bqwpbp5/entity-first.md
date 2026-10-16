---
title: The relational habit, and why it works there
version: 1
---

The first NoSQL schema most teams write is their relational schema with the joins removed: one
collection per table, one key per row, and the application doing the joining. **It is the commonest
mistake in this course's subject**, and it comes from a habit that is right in the place it was
learnt.

## Entities first, questions later

The `sql-databases` course designed the shop by asking what things exist and how they relate.
Customers place orders, orders have lines, lines name products. Each fact is written once, in the
table of the thing it describes: the city of a customer lives in `customers`, the price of a
product in `products`, and an order line holds only the keys that point at them. Normalisation is
the discipline of putting each fact in exactly one place, and its reward is that **no update can
leave two copies disagreeing**, because there are no copies.

Nothing in that design mentions a query. The schema describes the world, and the questions come
later, from anybody, in any shape.

## What makes that safe: the join and the planner

It works because a relational database promises to answer **a question nobody listed when the
tables were made**. An analyst writes, months after launch, "customers in Recife who bought a
monitor in September", a query touching four tables. The database answers it, correctly, without a
schema change:

- **the join** rebuilds, at read time, the combinations normalisation took apart;
- **the planner** decides how: which table to start from, which index to use, in which order to
  join, from statistics it keeps about the data.

So in a relational design the cost of a new question is paid **at read time**, and at worst it is an
index somebody adds later. That is a good bargain when the questions are many and unpredictable, and
when all the data sits on one machine where a join is a lookup in memory or on a local disk.

## What changes in the stores of this course

The three products give up some or all of that machinery, each for a reason lesson 2 showed:

| | joins | a planner choosing between strategies | so a question not designed for is |
|---|---|---|---|
| **Redis** | none | none: every command names its key | a scan of every key, done by the application |
| **Cassandra** | none | none: a query must start from a partition | refused, or `ALLOW FILTERING` across every node |
| **MongoDB** | `$lookup` in a pipeline, lesson 8 | yes, for indexes inside one collection | possible, and slow once the data is spread across shards |

The reason is the same in all three. They spread data across machines, and **a join across machines
is a conversation over the network for every row it matches**. A store designed to answer in a
millisecond from one partition cannot also promise to combine any two partitions on demand.

So the questions move. In a relational design they are answered at read time and nobody has to list
them first. Here they have to be known **at design time**, because the shape of the data is the
answer to them. Carrying the relational schema across, with its entities and without its joins,
keeps the cost of normalisation and throws away the thing that paid for it.

The next section writes the list the design starts from.
