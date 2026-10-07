---
title: Choosing, and doing it in SQL
version: 1
---

**The choice follows from two things: why the value is missing, and what the column will be used
for.** Lesson 3's log answers the first; the question being asked answers the second.

| the blank is | for a count or a sum | for an average | for an individual row |
|---|---|---|---|
| a known value (website discount) | fill the constant | fill the constant | fill the constant |
| not applicable (pickups) | leave it, exclude the rows | leave it, exclude the rows | leave it |
| MCAR | drop, and say how many remain | drop, or fill the centre | leave it blank |
| MAR | fill within groups | fill within groups | leave it blank |
| MNAR with a known bound (the timer) | flag, use the bound | flag, report a floor | flag |
| MNAR with no bound (the survey) | report the rate beside it | report the rate beside it | leave it blank |

The last column is the same in every row but one, and that is deliberate. **A guessed value
attached to a real person — their age, their score, their delivery — is a fabrication**, however
good the method. Imputation serves summaries.

## The decisions, in one view

In the database, Ana writes the decisions for the orders as a view over the raw table, so that
every query reads the decided version and the raw rows stay untouched:

```schooling-example
{
  "language": "sql",
  "file": "fill.sql",
  "parts": [
    {
      "code": "CREATE OR REPLACE VIEW orders_filled AS\nSELECT order_id,\n",
      "note": "**A view, not a table.** The decisions are applied every time it is read, and the raw rows underneath never change."
    },
    {
      "code": "       COALESCE(discount, '0')                        AS discount,\n",
      "note": "The website's blank discount becomes the zero it means."
    },
    {
      "code": "       delivery_minutes,\n",
      "note": "The time itself is left exactly as recorded, blanks included."
    },
    {
      "code": "       CASE WHEN fulfilment = 'pickup'    THEN 'no delivery'\n            WHEN status = 'cancelled'     THEN 'no delivery'\n            WHEN courier = 'Rapidex'      THEN 'not reported'\n            WHEN delivery_minutes IS NULL THEN 'over 120'\n            ELSE 'recorded' END                       AS timing\n",
      "note": "**The reason for every blank, in its own column.** The order of the `WHEN`s matters: a cancelled Rapidex order is `no delivery`, not `not reported`, because the first match wins."
    },
    {
      "code": "FROM (SELECT DISTINCT * FROM raw.orders) o;\n",
      "note": "`DISTINCT` drops the 25 repeated orders lesson 1 found."
    }
  ]
}
```

```
ana@lab:~/clean$ psql -f fill.sql
CREATE VIEW
ana@lab:~/clean$ psql -c 'SELECT timing, count(*) FROM orders_filled GROUP BY timing ORDER BY count(*) DESC'
    timing    | count 
--------------+-------
 recorded     | 14858
 not reported |  6620
 no delivery  |  6592
 over 120     |   456
(4 rows)
```

Every own-fleet blank is now `over 120`, every Rapidex blank `not reported`, every pickup and
cancelled order `no delivery`. **No delivery time was invented**; each blank carries its reason. A
report of late deliveries counts `recorded` rows of 90 minutes or more plus every `over 120`, and
gets the right answer.

And the missingness log from lesson 3 gains its last column — what was done:

| column | mechanism | done |
|---|---|---|
| `discount`, website | not missing | `COALESCE` to `0` |
| `delivery_minutes`, own fleet | MNAR, bound 120 | flagged `over 120` |
| `delivery_minutes`, Rapidex and pickups | not reported, not applicable | flagged |
| `birth_year` 1900 and two-digit | placeholder, invalid | blanked; summaries over known years only |
| `nps` | MNAR, no bound | left blank; response rate reported with the score |
