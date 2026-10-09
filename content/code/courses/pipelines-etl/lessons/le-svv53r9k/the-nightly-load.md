---
title: The nightly load
version: 1
---

Lesson 6 built tables by dropping and recreating them. That is fine for staging, which nobody reads
but the next layer, and wrong for the marts, which people read all day and which have to **keep
what they already hold** — last year's sales, where a customer lived in January. Loading is the
step that writes into a table that already has something in it, and **every way of doing it is a
decision about what happens to the rows that are there**.

Ana's warehouse gets three tables in `marts`, each loaded a different way:

| table | what one row is | how it is loaded |
|---|---|---|
| `dim_book` | a book, as it is now | upsert: insert the new, overwrite the changed |
| `dim_customer` | a customer, in one place, for a period | type 2: close the old version, open a new one |
| `fact_sales` | one order line that was sold | replace the whole day |

One script runs a night: copy the shop into `raw`, rebuild `staging`, then the three loads, in
that order, because the fact table looks the customer up in the dimension:

```
#!/bin/sh
# One night: copy the shop into raw, rebuild staging, then load the marts.
set -e
day=${1:?usage: nightly.sh YYYY-MM-DD}
export PGOPTIONS="-c client_min_messages=warning"
python load_raw.py >/dev/null
sh run_sql.sh >/dev/null
psql -q -v ON_ERROR_STOP=1 -d wh -f load/dim_customer.sql
psql -q -v ON_ERROR_STOP=1 -d wh -At -f load/dim_book.sql | sort | uniq -c | sed 's/t$/inserted/; s/f$/updated/'
psql -q -v ON_ERROR_STOP=1 -d wh -v day="$day" -f load/fact_sales.sql
psql -d wh -At -c "SELECT '$day: ' || count(*) || ' fact rows' FROM marts.fact_sales WHERE order_date = '$day'"
```

The first night, everything is new — 1,200 books inserted, 272 order lines, one version for each
of the 5,098 customers:

```
ana@vm:~/etl$ sh nightly.sh 2026-03-01
   1200 inserted
2026-03-01: 272 fact rows
ana@vm:~/etl$ psql -d wh -c "SELECT count(*) AS versions, count(DISTINCT customer_id) AS customers FROM marts.dim_customer"
 versions | customers 
----------+-----------
     5098 |      5098
(1 row)
```

The second night, after `shop` plays 2 March, the books did not change and nothing is printed for
them; the day's sales go in:

```
ana@vm:~/etl$ sudo shop day 2026-03-02
ana@vm:~/etl$ sh nightly.sh 2026-03-02
2026-03-02: 415 fact rows
```

The sections that follow take the three loads one at a time, starting with the one this script does
not use.
