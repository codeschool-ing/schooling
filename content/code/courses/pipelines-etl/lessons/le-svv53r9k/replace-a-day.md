---
title: Replacing a whole period
version: 1
---

A fact table is loaded a period at a time, and the period is the unit it can **replace**. Ana's
fact load deletes the day it is about to write, then inserts it, inside one transaction:

```
-- marts.fact_sales: one row per order line sold, for one day, replaced whole.
-- Run as: psql -v day=2026-03-07 -f load/fact_sales.sql
CREATE TABLE IF NOT EXISTS marts.fact_sales (
  order_date   date    NOT NULL,
  order_id     integer NOT NULL,
  line_no      integer NOT NULL,
  customer_key bigint  NOT NULL,   -- -1: no customer we can name
  book_id      integer NOT NULL,
  quantity     integer NOT NULL,
  line_cents   bigint  NOT NULL);

BEGIN;
DELETE FROM marts.fact_sales WHERE order_date = :'day';
INSERT INTO marts.fact_sales
SELECT o.order_date, o.order_id, l.line_no,
       coalesce(d.customer_key, -1),
       l.book_id, l.quantity, l.line_cents
  FROM staging.orders o
  JOIN staging.order_lines l USING (order_id)
  LEFT JOIN marts.dim_customer d
         ON d.customer_id = o.customer_id
        AND o.ordered_at >= d.valid_from
        AND (o.ordered_at < d.valid_to OR d.valid_to IS NULL)
 WHERE o.order_date = :'day' AND o.is_sale;
COMMIT;
```

`:'day'` is a psql variable, set on the command line with `-v day=2026-03-03`, so the same file
loads any day it is given — lesson 1's batch script made the same choice for the same reason.

Run the night of 2 March a second time, and the table is unchanged:

```
ana@vm:~/etl$ sh nightly.sh 2026-03-02
2026-03-02: 415 fact rows
ana@vm:~/etl$ psql -d wh -c "SELECT order_date, count(*) FROM marts.fact_sales GROUP BY 1 ORDER BY 1"
 order_date | count 
------------+-------
 2026-03-01 |   272
 2026-03-02 |   415
(2 rows)
```

**415 rows for 2 March, as before.** The delete removed the first run's rows and the insert put the
same rows back. And because both happen in one transaction, a reader never sees the day missing:
until the commit, PostgreSQL shows everybody else the old rows; after it, the new ones.

## The period has to match the source of truth

Replacing a day works because a day of the shop is a closed thing: everything that happened on 2
March can be read again from `staging`, whole. **The rule is that the period you delete must be a
period you can rebuild completely.** Delete a day and insert from an extraction that only had the
afternoon's rows, and the morning is gone.

That is also what makes late changes easy. When the shop refunds an order from 2 March on the 9th,
nothing has to find and update the fact row: rerunning the load for 2 March rebuilds the day
from what the shop now says, and the refunded order is no longer a sale. Lesson 15 makes that a
habit — reloading the last few days every night — and lesson 9 lets a scheduler do it.
