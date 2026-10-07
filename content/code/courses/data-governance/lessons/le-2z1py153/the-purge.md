---
title: The purge
version: 1
---

The purge turns the schedule into deletions. Ipê's is one function that reads only `gov.retention`
and `gov.legal_holds`, so changing a period or adding a hold never means editing it:

```sql
-- The purge: what gov.retention says has expired goes, except what a legal
-- hold keeps. Before orders go, what they say about sales is kept as monthly
-- totals that name nobody. Every run is logged.
SET ROLE ipe_owner;
CREATE TABLE gov.sales_monthly (
  month       date    NOT NULL,
  category    text    NOT NULL,
  orders      integer NOT NULL,
  units       integer NOT NULL,
  revenue_cts bigint  NOT NULL,
  PRIMARY KEY (month, category)
);
CREATE TABLE gov.purge_log (
  run_on  date        NOT NULL,
  rel     text        NOT NULL,
  deleted bigint      NOT NULL,
  PRIMARY KEY (run_on, rel)
);
INSERT INTO gov.column_class
SELECT 'gov', t, c, 'none', w
FROM (VALUES ('sales_monthly','month','totals that name nobody'),
             ('sales_monthly','category','totals that name nobody'),
             ('sales_monthly','orders','totals that name nobody'),
             ('sales_monthly','units','totals that name nobody'),
             ('sales_monthly','revenue_cts','totals that name nobody'),
             ('purge_log','run_on','a count of rows, not people'),
             ('purge_log','rel','a count of rows, not people'),
             ('purge_log','deleted','a count of rows, not people')) AS v(t, c, w);

CREATE FUNCTION gov.purge(today date) RETURNS TABLE (rel text, deleted bigint)
LANGUAGE plpgsql AS $$
DECLARE
  held    integer[] := ARRAY(SELECT customer_id FROM gov.legal_holds
                             WHERE released_on IS NULL);
  expired integer[];
  n       bigint;
BEGIN
  expired := ARRAY(
    SELECT o.order_id FROM sales.orders o
    WHERE date_trunc('year', o.ordered_at) + interval '1 year'
          + (SELECT keep_for FROM gov.retention WHERE table_name = 'orders') <= today
      AND (o.customer_id IS NULL OR o.customer_id <> ALL (held)));

  -- What the business still needs from them, anonymised (LGPD art. 16, IV).
  INSERT INTO gov.sales_monthly
  SELECT date_trunc('month', o.ordered_at)::date, p.category, count(DISTINCT o.order_id),
         sum(i.quantity), sum(i.quantity * i.unit_price_cents)
  FROM sales.orders o
  JOIN sales.order_items i USING (order_id)
  JOIN sales.products p USING (product_id)
  WHERE o.order_id = ANY (expired)
  GROUP BY 1, 2
  ON CONFLICT (month, category) DO UPDATE
    SET orders = gov.sales_monthly.orders + EXCLUDED.orders,
        units = gov.sales_monthly.units + EXCLUDED.units,
        revenue_cts = gov.sales_monthly.revenue_cts + EXCLUDED.revenue_cts;

  DELETE FROM health.prescriptions r
  WHERE (r.issued_on + (SELECT keep_for FROM gov.retention WHERE table_name = 'prescriptions')
         <= today OR r.order_id = ANY (expired))
    AND r.customer_id <> ALL (held);
  GET DIAGNOSTICS n = ROW_COUNT; rel := 'health.prescriptions'; deleted := n; RETURN NEXT;

  DELETE FROM support.tickets t
  WHERE t.status = 'closed'
    AND t.opened_at + (SELECT keep_for FROM gov.retention WHERE table_name = 'tickets') <= today
    AND t.customer_id <> ALL (held);
  GET DIAGNOSTICS n = ROW_COUNT; rel := 'support.tickets'; deleted := n; RETURN NEXT;

  DELETE FROM sales.order_items WHERE order_id = ANY (expired);
  DELETE FROM sales.payments    WHERE order_id = ANY (expired);
  DELETE FROM sales.deliveries  WHERE order_id = ANY (expired);
  DELETE FROM sales.returns     WHERE order_id = ANY (expired);
  DELETE FROM sales.orders      WHERE order_id = ANY (expired);
  GET DIAGNOSTICS n = ROW_COUNT; rel := 'sales.orders'; deleted := n; RETURN NEXT;
END $$;
```

The order of the work inside it matters:

1. **find what has expired**, skipping anything a hold covers — guest orders from 2019 have no customer
   and so no hold, which is why `customer_id IS NULL` is tested on its own;
2. **keep what the business still needs, anonymised**: monthly totals by product category, written
   before any order goes (section 6);
3. **delete the dependents first** — prescriptions, then the order's items, payment, delivery and
   return — and the orders last, so no foreign key is ever left pointing at nothing.

An earlier version used temporary tables, and the lab refused it: lesson 1 took the `TEMPORARY`
privilege away from everybody, and the function runs as `ipe_owner`. Arrays held in variables do the
same job without the privilege.

## Running it

```sql
-- One run, logged.
SET ROLE ipe_owner;
INSERT INTO gov.purge_log
SELECT DATE '2026-07-01', rel, deleted FROM gov.purge(DATE '2026-07-01')
RETURNING rel, deleted;
```

```
ana@lab:~/gov$ psql -f hold.sql
SET
CREATE TABLE
INSERT 0 4
INSERT 0 1
ana@lab:~/gov$ psql -f purge.sql
SET
CREATE TABLE
CREATE TABLE
INSERT 0 8
CREATE FUNCTION
ana@lab:~/gov$ psql -f run-purge.sql
SET
         rel          | deleted 
----------------------+---------
 health.prescriptions |    9826
 support.tickets      |     366
 sales.orders         |     950
(3 rows)

INSERT 0 3
ana@lab:~/gov$ psql -f overdue.sql
SET
        table         | past_retention 
----------------------+----------------
 sales.orders         |             13
 health.prescriptions |             21
 support.tickets      |              1
(3 rows)

ana@lab:~/gov$ psql -c "SET ROLE ipe_owner" -c "SELECT count(*) AS orders_kept_by_the_hold FROM sales.orders WHERE customer_id = 4407 AND ordered_at < DATE '2021-01-01'" -c "SELECT * FROM gov.sales_monthly WHERE month = DATE '2020-03-01' ORDER BY category"
SET
 orders_kept_by_the_hold 
-------------------------
                      13
(1 row)
```

**9,826 prescriptions, 366 tickets and 950 orders** gone, and the counts written to
`gov.purge_log`. The overdue query, run again, still finds 13, 21 and 1: those are customer 4407's
order, prescriptions and ticket, kept by the hold, and the next query confirms the 13 orders are
still there. The overdue query does not know about holds; the purge does. That difference is the
right one — the first is a report of what the schedule says, the second is what is allowed to happen.

## Running it every day

A purge that somebody remembers to run once a year is a purge that is a year late most of the time.
The function is written to be **run on a schedule**, as a nightly job with the date passed in. It is
also **safe to run twice**: on the same date there is nothing left to find, so a second run deletes
nothing and adds nothing to the totals, by construction. The log's key goes one step further and
refuses a second entry for the same date, so a job retried by mistake fails loudly instead of
writing a second line. The log then shows, every night, how much the schedule removed; a night with
zero rows is fine, and a month of nights with no log at all is the alarm.