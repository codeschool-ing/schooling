---
title: Did the segment's action work?
version: 1
---

The sales team calls the 173 frequent customers who are at risk. Next quarter, many of them have ordered
again. Did the calls work? There is no way to tell from that number alone, because some of them would
have ordered anyway — they are frequent customers, and a quiet patch is not a departure. The only way to
know is to **not call some of them**, chosen at random before anybody picks up a phone, and compare.

That group is a **holdout**. The choice has to be random, and it has to be stable: the same customer
must land in the same group every time the query runs, or a customer called on Monday could appear in
the holdout on Tuesday. A hash of the customer's id does both, and needs no table:

```
lantern=# SELECT CASE WHEN abs(hashtext(external_id)) % 5 = 0 THEN 'hold out' ELSE 'call' END AS arm,
lantern-#        count(*) AS customers, round(avg(net_revenue), 2) AS avg_net_revenue,
lantern-#        round(avg(orders), 2) AS avg_orders
lantern-# FROM activation.crm_contacts
lantern-# WHERE health = 'at risk' AND orders >= 4
lantern-# GROUP BY 1 ORDER BY 1;
   arm    | customers | avg_net_revenue | avg_orders 
----------+-----------+-----------------+------------
 call     |       136 |          861.51 |       5.73
 hold out |        37 |          971.67 |       5.57
(2 rows)
```

A fifth of the segment, 37 customers, is held out. `abs(hashtext(external_id)) % 5 = 0` puts a customer
in the holdout depending only on their id, so tomorrow's run gives the same answer for every customer who
is still in the segment. One caution: `hashtext` is a function PostgreSQL uses internally, and its values
are not promised to stay the same across major versions, so for a programme that will run for months,
write the assignment into a table on the first day and read it from there.

Look at the averages. Before anybody has been called, the holdout's customers have spent R$ 971.67 each
and the called group's R$ 861.51 — R$ 110 apart, by chance alone, because 37 is a small group and a few
large customers move its average. **This is what the comparison has to beat.** If next quarter the
called group orders more than the holdout by a margin of the same size, the calls may have done nothing.

Three rules, then:

- **Decide the holdout before the action**, and never move a customer out of it because they look
  promising. That is the whole of what makes it random.
- **Compare the change, not the level**: each group's orders after the calls against its own before.
- **Small segments give noisy answers.** With 37 people in the holdout only a large effect will show;
  a programme that runs for several quarters, or on a larger segment, can see a smaller one.
