---
title: Giving a guarantee up on purpose
version: 1
---

The useful question is never "is this database CP or AP". It is **"for this operation, what
happens to the business if two copies disagree for a while, and what happens if the operation
fails instead?"** Ask it per operation, because the answers differ inside one application.

## The shop, one operation at a time

| operation | if two copies disagree for a moment | if the operation is refused | so |
|---|---|---|---|
| take the last monitor out of stock | it is sold twice, and somebody gets a refund and an apology | the customer sees an error and tries again | **consistency** |
| charge the card for an order | the customer may be charged twice | the order waits | **consistency** |
| add an item to a basket | the basket shows one item fewer for a second | the customer cannot shop at all | **availability** |
| "customers also bought" | slightly old suggestions | an empty box on the page | **availability** |
| count a page view | the count is a few views behind | the view is lost, or the page fails | **availability, and latency** |

Two of the five need consistency and three would rather have the answer quickly. None of this is
specific to a product; it is a property of what the operation does to money, stock and trust.

## Where the three products start, before you change anything

Each product in this course has a default, and each default is somebody's guess about the common
case. These are the starting points the lessons go on to measure:

| | out of the box | what you can change |
|---|---|---|
| **MongoDB** replica set | writes and reads go to one primary; a write is acknowledged once a majority of members have it | lesson 9: how many members must acknowledge a write, and whether reads may go to a secondary |
| **Cassandra** | `cqlsh` reads and writes with consistency level `ONE`: one replica's answer is enough | lesson 17: per statement, from `ONE` to `ALL` |
| **Redis** with replicas | the primary answers at once and replicates in the background | lesson 15: `WAIT` makes a client wait for replicas, and still does not make Redis consistent in the theorem's sense |

So out of the box, a MongoDB replica set leans **PC/EC**, and Cassandra from `cqlsh` and Redis
with replicas lean **PA/EL**. Lesson 9 makes the MongoDB primary step down when it loses its
majority, lesson 17 runs the same Cassandra table both ways, and lesson 15 loses an acknowledged
Redis write on purpose. Those three are the theorem as you can watch it happen.

## The cost of choosing in the wrong direction

Giving up consistency where you needed it costs **an incident**: double sales, double charges, a
stock figure nobody trusts. It usually surfaces weeks later, in a reconciliation, after the logs
that would explain it are gone.

Giving up availability or latency where you did not need to costs **every request**: slower pages
and errors during every small network event, for a guarantee the operation never used. It is
cheaper per day and paid every day, and it is the reason teams move operations off a single strict
database in the first place.

Choosing on purpose means writing the table above for your own system before you pick settings.
Lessons 3 and 4 do the same thing for the shape of the data rather than for its copies.
