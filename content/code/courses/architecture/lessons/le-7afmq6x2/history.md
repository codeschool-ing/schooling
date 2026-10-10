---
title: What the history buys
version: 1
---

Keeping every change costs storage and some complexity. What it buys is the subject of this section,
and it is the reason to choose event sourcing at all.

**The past, exactly.** The state of an order at any version is a replay that stops early. The customer
says the tea was in the basket when they looked; it was, at version 3:

```
ana@vm:~/lab/events$ $O show o-1 3
o-1 at v3: open, coffee x2, tea x1
```

**Questions nobody planned for.** Months after launch, somebody asks which products people put in their
basket and then take out before paying. In an ordinary orders table the answer is gone: an `UPDATE`
removed the tea and kept no trace. Here every removal is still an event:

```
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c "SELECT data->>'product' AS product, count(*) AS removed FROM events WHERE type = 'ItemRemoved' GROUP BY 1"
 product | removed 
---------+---------
 tea     |       1
(1 row)
```

**Read models you did not have on day one.** A read model is a function of the events, so a new one can
be built from all of history, and a wrong one can be thrown away and rebuilt. Empty both of the lab's
and project everything again:

```
ana@vm:~/lab/events$ $O rebuild
applied 9 events, checkpoint now at 9
ana@vm:~/lab/events$ docker compose exec -T db psql -U postgres -c 'SELECT * FROM units_sold'
 product | units 
---------+-------
 coffee  |     2
 rice    |     3
 tea     |     4
(3 rows)
```

Nine events replayed from position 1, and the tables are exactly what they were. A new screen, a
report for the accountant, a search index from lesson 17: each starts as a new projection run over
everything that ever happened, instead of a migration and a backfill.

**An audit trail that is the data**, not a log kept beside it that might disagree. For orders, payments,
stock movements and anything a regulator or a customer may ask about later, that alone can justify the
design.
