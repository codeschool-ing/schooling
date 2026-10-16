---
title: The repair, and what a point in time costs
version: 1
---

There are now two shops. The live one has the three orders that arrived after the `DELETE`, and is
missing twelve thousand older ones. The restored one has the twelve thousand and not the three. A
point-in-time recovery hands you that choice, and there are two ways to take it.

**Replace the live database with the restored one.** Everything written after the target is lost:
here three orders, in a real shop every order, payment and sign-up since the mistake. That is right
when the mistake was so wide (a dropped schema, a corrupted table) that nothing after it can be
trusted, and it is the only option when the live server is gone altogether.

**Repair the live database from the restored one.** The restored copy is used the way lesson 2 used
a side copy: as a source of the rows that were lost, copied back into the live database, which keeps
everything since. Here the lost rows are exactly the orders from before March:

```
ana@vm:~$ psql -p 5433 shop -c "\copy (SELECT * FROM orders WHERE placed_at < '2026-03-01') TO 'deleted.csv' CSV"
COPY 12059
ana@vm:~$ psql shop -c "\copy orders FROM 'deleted.csv' CSV"
COPY 12059
ana@vm:~$ psql shop -c "SELECT count(*), min(placed_at) FROM orders"
 count |          min           
-------+------------------------
 50008 | 2026-01-01 09:07:00-03
(1 row)
```

**50008 orders, from 1 January**: the fifty thousand, the five before the mistake and the three after
it. The repair took the shop back to what it should be and lost nothing.

It was easy because the `DELETE` touched only rows nothing else had touched since. On a real
database, the rows a mistake damaged are often changed again afterwards, referenced by new rows, or
counted in totals somebody has already reported, and the repair becomes a set of queries that join
the two copies and have to be checked by a person. The restored copy is what makes those queries
possible. **Without it, the only question you can answer is how much was lost.**

Which way to go is a decision, and it is usually not the database administrator's alone: it trades
data written after the mistake against the time a careful repair takes. Lesson 22 is about who
makes that decision during an incident and how.
