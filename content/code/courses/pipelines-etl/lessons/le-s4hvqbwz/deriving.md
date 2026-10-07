---
title: Deriving: the column nobody stored
version: 1
---

Much of a transformation is adding columns the source never had, because the source never needed
them: what a line was worth, whether an order counts as a sale, which day it happened on. The two
staging files for orders and lines are almost nothing else:

```
-- One row per order, as the shop has it, with the shop's own date worked out once.
DROP TABLE IF EXISTS staging.orders CASCADE;
CREATE TABLE staging.orders AS
SELECT order_id,
       shop_id,
       customer_id,
       ordered_at,
       (ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS order_date,
       status,
       status = 'completed' AS is_sale
  FROM raw.orders;
```

```
-- One row per order line, with what the line was worth.
DROP TABLE IF EXISTS staging.order_lines CASCADE;
CREATE TABLE staging.order_lines AS
SELECT order_id,
       line_no,
       book_id,
       quantity,
       unit_price_cents,
       quantity * unit_price_cents AS line_cents
  FROM raw.order_lines;
```

Each derived column is a decision written once. `is_sale` says that a refunded order is not a sale,
and every report that reads it inherits the decision instead of repeating `status = 'completed'`
— or, worse, repeating it slightly differently. `line_cents` says that revenue is quantity times the
price paid, not the list price.

## The derivation that is easy to get wrong

`order_date` looks like the most innocent column in the warehouse. **A timestamp does not have a
date; a timestamp in a time zone does.** `ordered_at` is a moment, stored as UTC inside PostgreSQL,
and the date it falls on depends on where you are standing when you ask. Here are two days of
orders, dated in São Paulo and then dated the way a server set to UTC would date them:

```
ana@vm:~/etl$ psql -d wh -c "SELECT (ordered_at AT TIME ZONE 'America/Sao_Paulo')::date AS sao_paulo_day, count(*) FROM raw.orders WHERE ordered_at >= '2026-03-06' AND ordered_at < '2026-03-08' GROUP BY 1 ORDER BY 1"
 sao_paulo_day | count 
---------------+-------
 2026-03-06    |   279
 2026-03-07    |   344
(2 rows)

ana@vm:~/etl$ PGTZ=UTC psql -d wh -c "SELECT ordered_at::date AS utc_day, count(*) FROM raw.orders WHERE ordered_at >= '2026-03-06 00:00-03' AND ordered_at < '2026-03-08 00:00-03' GROUP BY 1 ORDER BY 1"
  utc_day   | count 
------------+-------
 2026-03-06 |   252
 2026-03-07 |   337
 2026-03-08 |    34
(3 rows)
```

The same 623 orders. In São Paulo they belong to the 6th and the 7th. In UTC, every order placed
after 21:00 local time has moved to the next day — 27 from Friday into Saturday, 34 from Saturday
into a Sunday that, in São Paulo, had not started yet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l06-zones\" aria-label=\"Two clocks over the same evening. On the São Paulo clock, Friday runs until midnight. On the UTC clock, the day changes at 21:00 São Paulo time, so every order between 21:00 and midnight is dated Saturday.\"><text x=\"108.0\" y=\"72.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">São Paulo</text><rect x=\"120.0\" y=\"60.0\" width=\"420.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"540.0\" y=\"60.0\" width=\"140.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Friday 6 March</text><text x=\"610.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Saturday 7 March</text><text x=\"108.0\" y=\"142.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">UTC</text><rect x=\"120.0\" y=\"130.0\" width=\"315.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"435.0\" y=\"130.0\" width=\"245.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"277.5\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Friday 6 March</text><text x=\"557.5\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Saturday 7 March</text><path d=\"M435.0 40.0 L435.0 56.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M435.0 88.0 L435.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M435.0 158.0 L435.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M540.0 40.0 L540.0 56.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M540.0 88.0 L540.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M540.0 158.0 L540.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"487.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">orders placed 21:00–24:00</text><text x=\"487.5\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">dated Saturday in UTC</text><text x=\"120.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12:00</text><text x=\"260.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16:00</text><text x=\"400.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20:00</text><text x=\"540.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">00:00</text><text x=\"680.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">04:00</text></svg>", "caption": "The same moment falls on two dates. Whose day it is has to be written into the derivation, once."}
```

**Nothing in that second query is wrong as SQL.** `::date` is valid; the server's time zone is a
setting somebody chose. The two answers disagree because nobody wrote down whose day it is, and the
first report that notices will be a manager asking why Saturday's sales are lower in the warehouse
than on the tills.

So `order_date` is derived in staging, once, with the zone written out, and nothing downstream is
allowed to derive a date from `ordered_at` again. Ponto Final's day is São Paulo's. A business that
sells in several zones has to decide whose day is the reporting day, and write that down instead.
