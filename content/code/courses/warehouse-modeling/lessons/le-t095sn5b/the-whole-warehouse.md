---
title: The whole warehouse, in one script
version: 1
---

Every lesson after this one asks questions of the same warehouse, and part of it is explained only
later: the customer dimension in lesson 5, the authors in lesson 4, and versions of this
lesson's fact tables that point at a customer. **This section gives you all of it now**, so that
the next lesson has something to run on. Save the files in `~/wh`, and read each one when the lesson
that explains it comes round.

The customer dimension, which lesson 5 builds and explains. It keeps one row per customer for every
stretch of time in which nothing about them changed, so that a sale can point at the customer as
they were on the day:

```sql
-- Slowly changing, type 2 on tier, city and state: a new row every time one
-- of them changed, each row valid from the change until the next one.
-- The name is type 1: every version carries the name as it is spelled now.
CREATE TABLE dim_customer AS
WITH tracked AS (
    SELECT * FROM staging.customer_changes WHERE field IN ('tier', 'city', 'state')
),
-- what each tracked field held when the customer joined: the old value of its
-- first change, or the current value if it never changed
first_values AS (
    SELECT c.customer_id, c.created_at AS valid_from,
           coalesce((SELECT old_value FROM tracked t WHERE t.customer_id = c.customer_id
                     AND t.field = 'tier' ORDER BY changed_at LIMIT 1), c.tier)  AS tier,
           coalesce((SELECT old_value FROM tracked t WHERE t.customer_id = c.customer_id
                     AND t.field = 'city' ORDER BY changed_at LIMIT 1), c.city)  AS city,
           coalesce((SELECT old_value FROM tracked t WHERE t.customer_id = c.customer_id
                     AND t.field = 'state' ORDER BY changed_at LIMIT 1), c.state) AS state
    FROM staging.customers c
),
-- one event per moment something tracked changed
moments AS (
    SELECT customer_id, changed_at AS valid_from,
           max(new_value) FILTER (WHERE field = 'tier')  AS tier,
           max(new_value) FILTER (WHERE field = 'city')  AS city,
           max(new_value) FILTER (WHERE field = 'state') AS state
    FROM tracked GROUP BY customer_id, changed_at
),
timeline AS (
    SELECT * FROM first_values
    UNION ALL
    SELECT * FROM moments
),
-- carry each field forward until the moment that changes it
versions AS (
    SELECT customer_id, valid_from,
           last_value(tier IGNORE NULLS)  OVER w AS tier,
           last_value(city IGNORE NULLS)  OVER w AS city,
           last_value(state IGNORE NULLS) OVER w AS state,
           lead(valid_from) OVER (PARTITION BY customer_id ORDER BY valid_from) AS next_from
    FROM timeline
    WINDOW w AS (PARTITION BY customer_id ORDER BY valid_from
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
)
SELECT row_number() OVER (ORDER BY v.customer_id, v.valid_from) AS customer_key,
       v.customer_id,
       c.name,
       v.tier,
       v.city,
       v.state,
       v.valid_from,
       coalesce(v.next_from, TIMESTAMPTZ '9999-12-31 00:00:00-03') AS valid_to,
       v.next_from IS NULL                                     AS is_current
FROM versions v JOIN staging.customers c USING (customer_id)
UNION ALL
SELECT 0, NULL, 'Walk-in, not identified', 'none', 'Unknown', '--',
       TIMESTAMPTZ '1970-01-01 00:00:00-03', TIMESTAMPTZ '9999-12-31 00:00:00-03', true
ORDER BY customer_key;
```

The author dimension, and the bridge between a book and its authors, which lesson 4 explains:

```sql
CREATE TABLE dim_author AS
SELECT row_number() OVER (ORDER BY author_id) AS author_key, author_id, name AS author_name,
       country
FROM staging.authors;

-- A book can have several authors, so the link is a table of its own. The
-- weight divides a book's sales between them and adds up to 1 per book.
CREATE TABLE bridge_book_author AS
SELECT b.book_key, a.author_key, ba.position,
       1.0 / count(*) OVER (PARTITION BY ba.book_id) AS weight
FROM staging.book_authors ba
JOIN dim_book b   ON b.book_id = ba.book_id
JOIN dim_author a ON a.author_id = ba.author_id;
```

`fact_sales.sql` and `fact_fulfilment.sql` replace this lesson's versions. Each gains a
`customer_key`, found by asking which version of the customer was in force when the order was placed;
an order with no customer on it, as many till sales are, gets key 0, which lesson 4 explains.

```sql
-- Grain: one row per line of an order that was not cancelled.
CREATE TABLE fact_sales AS
SELECT d.date_key,
       s.shop_key,
       b.book_key,
       coalesce(c.customer_key, 0)                     AS customer_key,
       coalesce(l.promotion_id, 0)                     AS promotion_key,
       o.order_id,
       l.line_no,
       l.quantity,
       l.quantity * l.unit_price_cents                 AS gross_cents,
       l.discount_cents,
       l.quantity * l.unit_price_cents - l.discount_cents AS net_cents
FROM staging.order_lines l
JOIN staging.orders o USING (order_id)
JOIN dim_date d       ON d.date = CAST(o.ordered_at AS DATE)
JOIN dim_shop s       ON s.shop_id = o.shop_id
JOIN dim_book b       ON b.book_id = l.book_id
LEFT JOIN dim_customer c
       ON c.customer_id = o.customer_id
      AND o.ordered_at >= c.valid_from AND o.ordered_at < c.valid_to
WHERE o.status <> 'cancelled'
ORDER BY o.order_id, l.line_no;
```

```sql
-- Grain: one row per online order, updated as it moves. A milestone not
-- reached yet points at the 'Not yet' date, key 0.
CREATE TABLE fact_fulfilment AS
SELECT o.order_id,
       c.customer_key,
       CAST(strftime(o.ordered_at, '%Y%m%d') AS INTEGER)                  AS ordered_date_key,
       coalesce(CAST(strftime(o.paid_at, '%Y%m%d') AS INTEGER), 0)        AS paid_date_key,
       coalesce(CAST(strftime(o.shipped_at, '%Y%m%d') AS INTEGER), 0)     AS shipped_date_key,
       coalesce(CAST(strftime(o.delivered_at, '%Y%m%d') AS INTEGER), 0)   AS delivered_date_key,
       o.status,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.shipped_at AS DATE))   AS days_to_ship,
       date_diff('day', CAST(o.ordered_at AS DATE), CAST(o.delivered_at AS DATE)) AS days_to_deliver
FROM staging.orders o
JOIN staging.shops sh USING (shop_id)
JOIN dim_customer c
  ON c.customer_id = o.customer_id
 AND o.ordered_at >= c.valid_from AND o.ordered_at < c.valid_to
WHERE sh.channel = 'online' AND o.status <> 'cancelled'
ORDER BY o.order_id;
```

`fact_payments.sql` is new. Lesson 4 is about why a payment needs a table of its own:

```sql
-- Grain: one row per payment. Most orders have one; some have two.
CREATE TABLE fact_payments AS
SELECT d.date_key, s.shop_key, coalesce(c.customer_key, 0) AS customer_key,
       p.order_id, p.payment_id, p.method, p.installments, p.amount_cents
FROM staging.payments p
JOIN staging.orders o USING (order_id)
JOIN dim_date d ON d.date = CAST(o.ordered_at AS DATE)
JOIN dim_shop s ON s.shop_id = o.shop_id
LEFT JOIN dim_customer c
       ON c.customer_id = o.customer_id
      AND o.ordered_at >= c.valid_from AND o.ordered_at < c.valid_to
ORDER BY p.payment_id;
```

And `fact_event_attendance.sql` takes the place of `fact_attendance.sql`, with the author and the
customer as they were at six in the evening, when the events start:

```sql
-- Grain: one row per customer who came to an author's event. No measure:
-- the row is the fact. The events start at six in the evening.
CREATE TABLE fact_event_attendance AS
SELECT d.date_key, s.shop_key, a.author_key, c.customer_key
FROM staging.event_attendance ea
JOIN staging.events e USING (event_id)
JOIN dim_date d   ON d.date = e.held_on
JOIN dim_shop s   ON s.shop_id = e.shop_id
JOIN dim_author a ON a.author_id = e.author_id
JOIN dim_customer c
  ON c.customer_id = ea.customer_id
 AND e.held_on + INTERVAL 18 HOUR >= c.valid_from
 AND e.held_on + INTERVAL 18 HOUR < c.valid_to
ORDER BY d.date_key, s.shop_key;
```

The script that runs them, in an order where every table is built after the tables it points at.
It starts from a fresh extract, so whatever the shop's database holds when you run it is what the
warehouse will hold. Save it as `~/wh/build.sh`:

```sh
#!/bin/sh
# Build the whole warehouse from nothing: a fresh extract of the shop's
# database, the staging layer, every dimension, then the facts that point at
# them.
set -e
rm -rf extract wh.duckdb wh.duckdb.wal
sh extract.sh
for f in staging dim_date dim_shop dim_book dim_customer dim_promotion dim_author \
         fact_sales fact_inventory fact_fulfilment fact_payments fact_event_attendance; do
  duckdb wh.duckdb < $f.sql
done
```

```
ana@lab:~/wh$ time sh build.sh

real	0m6.056s
user	0m5.844s
sys	0m1.315s
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT table_name, estimated_size AS rows FROM duckdb_tables() WHERE schema_name = 'main' ORDER BY table_name"
┌───────────────────────┬────────┐
│      table_name       │  rows  │
│        varchar        │ int64  │
├───────────────────────┼────────┤
│ bridge_book_author    │   3570 │
│ dim_author            │   1800 │
│ dim_book              │   3000 │
│ dim_customer          │  49309 │
│ dim_date              │    732 │
│ dim_promotion         │     11 │
│ dim_shop              │      7 │
│ fact_event_attendance │   2923 │
│ fact_fulfilment       │ 244275 │
│ fact_inventory        │ 197574 │
│ fact_payments         │ 586405 │
│ fact_sales            │ 887477 │
└───────────────────────┴────────┘
  12 rows              2 columns
```

Twelve tables in six seconds, on a machine shared with other work. Every lesson from 3 to 12 was recorded on a shop's database
exactly as lesson 1 loaded it and a warehouse fresh from this script. Lessons change both as they go,
and lesson 1 added an order of its own, so to start a lesson where its transcripts start:

```sh
dropdb shop && createdb --locale=C.UTF-8 --template=template0 shop
psql -q -f oltp.sql && sh load.sh && sh build.sh
```
