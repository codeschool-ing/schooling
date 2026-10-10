---
title: The three suspects, one at a time
version: 1
---

"The database is slow" is a sentence about a building. Inside it there are three suspects, and
the first habit this course teaches is to name which one you mean before you change anything:

| suspect | what is wrong | what fixes it |
|---|---|---|
| **the query** | it asks for more work than the answer needs | rewriting the query |
| **the schema** | the structure that would make the work small is missing | an index, a different table layout |
| **the machine** | something the work needs is short: memory, disk, processors | configuration, or a bigger machine |

The fixes do not transfer. An index does nothing for a server that is out of memory, and a bigger
machine does nothing for a query that reads two million rows to count two thousand. That is why
naming the suspect comes first: a fix applied to the wrong one costs time and changes nothing, and
sometimes it makes the right fix harder to see.

The three below are each slow for one reason, on the database you just loaded. You do not have
to understand yet *why* the server did what it did — lessons 3 to 5 teach you to read that. What
matters now is that the three slownesses look alike from outside, and are not.

## The query

Two ways to ask how many orders were placed on the first of June 2025:

```
market=# SELECT count(*) FROM orders WHERE date(placed_at) = '2025-06-01';
 count 
-------
  2801
(1 row)

Time: 118.968 ms

market=# SELECT count(*) FROM orders WHERE placed_at >= '2025-06-01' AND placed_at < '2025-06-02';
 count 
-------
  2801
(1 row)

Time: 1.295 ms
```

Same answer, same table, same server: **119 milliseconds against 1.3**, about ninety times.
The first query wraps the column in a function, `date(placed_at)`, and the index on `placed_at`
is a list of `placed_at` values in order, not of `date(placed_at)` values. So the server cannot
use it, and it computes the date of every one of the two million orders to find the 2801 that
match. The second asks the same question in the terms the index is written in, a range of
`placed_at`, and the index hands over exactly those rows.

Nothing about the schema or the machine changed. **The query was the suspect, and rewriting it
was the fix.** Lesson 9 shows the other way out, an index built on the expression itself, and
when each one is right.

## The schema

How many orders does seller 42 have?

```
market=# SELECT count(*) FROM orders WHERE seller_id = 42;
 count 
-------
  1532
(1 row)

Time: 55.253 ms

market=# CREATE INDEX orders_seller_id_idx ON orders (seller_id);
CREATE INDEX
Time: 1154.341 ms (00:01.154)

market=# SELECT count(*) FROM orders WHERE seller_id = 42;
 count 
-------
  1532
(1 row)

Time: 0.816 ms

market=# DROP INDEX orders_seller_id_idx;
DROP INDEX
Time: 12.035 ms
```

**55 milliseconds, then 0.8.** This time the query was fine: it asks for exactly what it wants,
in the simplest terms. What was missing is structure. With no index on `seller_id`, the only way
to find seller 42's orders is to read all of them, and an index turned two million rows read
into 1532.

The index was dropped again at the end. That is deliberate: lesson 2 finds this same missing
index from the outside, the way you would at work, from what the application is doing to the
server, rather than from somebody who already knows the answer.

Notice the third number too. **Building the index took 1154 milliseconds**, and every order
written from then on would pay a little more to keep it up to date. An index is not free, and
lesson 11 is about the ones that cost more than they save.

## The machine

The third suspect is the one no query and no index can fix. The same count over the five million
order lines takes **435 milliseconds** when the table has to come from the disk and about **170**
when it is already in memory — same query, same plan, same rows, on the same computer. Nothing in
the database changed between the two; only where the bytes were. The next section takes that
measurement apart, because it is also the reason one timing on its own proves nothing.

## What the three have in common

From outside, each of the three was "a slow query". From inside they were a question asked in the
wrong terms, a structure that was missing and data that was not in memory, and **each fix would
have done nothing for the other two**. The rest of this course is mostly about telling them apart
quickly, and the first tool for that is not a fix at all — it is the next lesson's list of which
queries cost the server the most.
