---
title: Outliers, and the three things one can be
version: 1
---

An **outlier** is a value far from the others. The word sounds like a verdict and is only an
observation: whether the row is a mistake, a different kind of customer, or a real event that
happened once, is something you find out. Deleting outliers because they are outliers is the
commonest way to make a table look tidier and say something false.

## Finding them

A conventional rule, from the statistician John Tukey, draws two **fences** one and a half IQRs
beyond the quartiles and calls anything outside them an outlier:

```
lantern=# WITH q AS (
lantern(#   SELECT percentile_cont(0.25) WITHIN GROUP (ORDER BY gross_cents) AS q1,
lantern(#          percentile_cont(0.75) WITHIN GROUP (ORDER BY gross_cents) AS q3
lantern(#   FROM order_totals)
lantern-# SELECT q1 - 1.5 * (q3 - q1) AS low_fence,
lantern-#        q3 + 1.5 * (q3 - q1) AS high_fence,
lantern-#        (SELECT count(*) FROM order_totals, q
lantern(#          WHERE gross_cents > q3 + 1.5 * (q3 - q1)) AS above
lantern-# FROM q;
 low_fence | high_fence | above 
-----------+------------+-------
  -13322.5 |    34977.5 |   591
(1 row)
```

The low fence is negative, so no order can fall below it; the high fence is R$ 349.78, and 591
orders are above it. That is more than one order in twelve, which is too many to be typos. The
rule found something real — what, it cannot say:

```
lantern=# SELECT c.segment, count(*) AS above_fence
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# WHERE t.gross_cents > 34977.5
lantern-# GROUP BY c.segment;
 segment | above_fence 
---------+-------------
 office  |         428
 home    |         163
(2 rows)
```

428 of the 591 are office orders, and 428 is most of the 684 office orders there are. **The rule
was measuring the wrong population**: against home orders, an office order is far out; against
other office orders, it is ordinary. That is the second thing an outlier can be, and the right
response is not to remove it but to stop mixing it with the others.

## The ones at the very top

```
lantern=# SELECT t.order_id, t.customer_id, c.segment, t.gross_cents / 100 AS gross_brl
lantern-# FROM order_totals t JOIN customers c USING (customer_id)
lantern-# ORDER BY t.gross_cents DESC LIMIT 6;
 order_id | customer_id | segment | gross_brl 
----------+-------------+---------+-----------
      412 |         561 | home    |     23980
      415 |         295 | home    |      9180
      431 |         191 | home    |      8900
     2010 |        1242 | office  |      3974
     5986 |        1867 | office  |      3778
     4280 |        1215 | office  |      3446
(6 rows)
```

The largest three are home customers, with orders of R$ 23,980, R$ 9,180 and R$ 8,900. A person
buying coffee at home does not spend R$ 23,980 in one order, and the next three, all offices,
spend under R$ 4,000. Look at the lines behind them, against the price list:

```
lantern=# SELECT l.order_id, l.product_id, l.quantity, l.unit_cents, p.price_cents
lantern-# FROM order_lines l JOIN products p USING (product_id)
lantern-# WHERE l.unit_cents <> p.price_cents
lantern-# ORDER BY l.order_id;
 order_id | product_id | quantity | unit_cents | price_cents 
----------+------------+----------+------------+-------------
        1 |          1 |        1 |          1 |        3490
        9 |          1 |        1 |          1 |        3490
        9 |          1 |        1 |          1 |        3490
       20 |          1 |        1 |          1 |        3490
       20 |          1 |        1 |          1 |        3490
       20 |          1 |        1 |          1 |        3490
       32 |          1 |        1 |          1 |        3490
      412 |          2 |        2 |    1199000 |       11990
      415 |          3 |        2 |     459000 |        4590
      431 |         10 |        1 |     890000 |        8900
(10 rows)
```

Two different faults in one query. Orders 412, 415 and 431 each have one line whose unit price is
exactly a hundred times the product's: 1,199,000 cents for a bag that costs 11,990. That is the
signature of a conversion done twice — a price in reais turned into cents by somebody who did not
know it was already in cents. **That is the first kind: an error**, and it has a correct value
that can be computed, so the fix belongs in the data, done by whoever owns the load, and reported
— not quietly divided by a hundred in your query and forgotten.

The other seven rows are customer 1, whose lines cost one cent.

## The ones at the very bottom

```
lantern=# SELECT order_id, customer_id, gross_cents FROM order_totals ORDER BY gross_cents LIMIT 5;
 order_id | customer_id | gross_cents 
----------+-------------+-------------
       32 |           1 |           1
        1 |           1 |           1
        9 |           1 |           2
       20 |           1 |           3
     6458 |         965 |        1590
(5 rows)

lantern=# SELECT customer_id, signed_up, state, channel FROM customers WHERE customer_id = 1;
 customer_id | signed_up  | state | channel 
-------------+------------+-------+---------
           1 | 2025-01-02 | SP    | email
(1 row)
```

Four orders worth one to three cents, all from customer 1, who signed up on the shop's second day
through the `email` channel. One-cent orders of the cheapest product are what a team does when it
tests the checkout on the live shop. **This is not an outlier in the statistical sense** — at
one cent it sits well inside the fences — and it is still a row that should not be in a report of
sales. Exploratory analysis finds it by looking at the minimum, which is why the minimum and the
maximum are always worth one query each.

## Deciding

Three kinds, three responses:

| what it is | here | what to do |
|---|---|---|
| an error | the three lines priced a hundred times too high | fix it at the source, and say how many rows it touched |
| a different population | office orders | analyse it separately; never average it with the rest |
| a real but rare event | none yet — a customer who really did buy R$ 9,000 of coffee | keep it, and report the median beside the mean |

The internal test account is a fourth thing that is none of the three, and real data has it
everywhere: rows produced by the company itself. **Whatever you exclude, write down what and why,
next to the number**: "excluding customer 1, the shop's test account (4 orders)". A number with a
silent exclusion cannot be reproduced by the next person who asks.
