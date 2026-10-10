---
title: Writing it down, and taking it out
version: 1
---

The decision was no. What remains is to undo the change in a way that leaves the next person
better off than if it had never been made — which means removing it **and** keeping what was
learnt, because the same index will be proposed again by somebody who reads the same textbook.

## Keep the definition before you drop

```
market=# SELECT pg_get_indexdef('orders_customer_placed_idx'::regclass);
                                          pg_get_indexdef                                           
----------------------------------------------------------------------------------------------------
 CREATE INDEX orders_customer_placed_idx ON public.orders USING btree (customer_id, placed_at DESC)
(1 row)

Time: 1.483 ms

market=# DROP INDEX orders_customer_placed_idx;
DROP INDEX
Time: 76.534 ms
EXIT 0
```

`pg_get_indexdef` prints the exact statement that would rebuild the index, as the server stores it:
the schema, the method and the column order. Copy it into the record below before the `DROP`. An
index removed without its definition is an index nobody can put back quickly on the day it turns
out somebody did need it — and lesson 11 showed that "nobody uses it" is a claim with exceptions.

The drop itself took **76 milliseconds** and an `ACCESS EXCLUSIVE` lock on `orders` for that time,
which on a quiet virtual machine is nothing. On a busy table, `DROP INDEX CONCURRENTLY` does the same
without blocking writes, at the price of taking longer; lesson 11 section 06 is about doing it
safely.

## A record of the change

Every optimisation, kept or not, is worth one short record where the team keeps its decisions — a
ticket, a file in the repository beside the migrations, a page of the runbook `db-administration`
lesson 24 is about. Six lines are enough, and each of them is there because its absence has cost
somebody a day:

```localised
change     CREATE INDEX orders_customer_placed_idx ON public.orders USING btree (customer_id, placed_at DESC)
why        the customer's order list is half of all transactions; its plan sorts
measured   workload of lesson 2, 3 runs x 30 s before and after, tally reset between
result     statement mean 0.107 -> 0.089 ms; write latency within noise; rate within noise
cost       60 MB (the index it would sit beside is 18 MB); one more entry per order written
decision   dropped: about 1% of one processor saved, at a time when two other statements take most of the server
```

**`measured` is the line people leave out**, and it is the one that makes the record worth reading.
Without it, "0.107 to 0.089" cannot be checked, repeated or compared with next year's measurement on
a bigger database, where the same index might well be worth it.

## When to look again

A decision like this one is true of the database as it was measured. It stops being true when the
numbers change: the customer's order list climbs the tally, customers start having hundreds of
orders each rather than ten, or the server reaches the knee of lesson 23's curve. The record says what
was measured, so the day any of that happens, repeating the measurement is an hour's work rather
than a week's argument.

That is what this course has been about from its first lesson: **name the suspect, measure, change
one thing, measure again the same way, and decide on the numbers**. Most of the time the numbers
say yes. The habit is worth the same when they say no.

Run `~/reset-market.sh` to leave `market` as the course found it.
