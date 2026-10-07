---
title: The same profile in SQL, and the profile written down
version: 1
---

**Everything in this lesson can be done where the data already is.** When a table has millions of
rows, pulling it into pandas to count its distinct values is the slow way round; the database
counts them where they lie. The measurements are the same and so are the findings.

One column's profile is one query:

```
ana@lab:~/clean$ psql -c "SELECT count(*) AS rows, count(cep) AS filled, count(DISTINCT cep) AS distinct_values, min(length(cep)) AS shortest, max(length(cep)) AS longest FROM raw.customers"
 rows | filled | distinct_values | shortest | longest 
------+--------+-----------------+----------+---------
 2413 |   2413 |            2360 |        7 |       9
(1 row)
```

`count(cep)` counts the non-null values and `count(*)` counts rows, so their difference is the
empty cells, exactly as `filled` and `empty` were in pandas. `count(DISTINCT …)`, `min(length(…))`
and `max(length(…))` are the rest.

The pattern profile is two nested `regexp_replace` calls, digits first and then letters:

```
ana@lab:~/clean$ psql -c "SELECT regexp_replace(regexp_replace(cep, '[0-9]', '9', 'g'), '[[:alpha:]]', 'a', 'g') AS pattern, count(*) FROM raw.customers GROUP BY 1 ORDER BY 2 DESC"
  pattern  | count 
-----------+-------
 99999-999 |  1322
 99999999  |   803
 9999999   |   288
(3 rows)
```

The same three shapes, with the same counts, from a different tool. `[[:alpha:]]` is
PostgreSQL's class for a letter in any alphabet, playing the part of `[^\W\d_]` in Python, and the
`'g'` flag replaces every match rather than the first.

Patterns work on any text, including the money the shops' till writes:

```
ana@lab:~/clean$ psql -c "SELECT regexp_replace(total, '[0-9]', '9', 'g') AS pattern, count(*) FROM raw.store_sales GROUP BY 1 ORDER BY 2 DESC"
  pattern  | count 
-----------+-------
 R$ 99,99  | 19308
 R$ 999,99 |  3395
 R$ 9,99   |   891
(3 rows)
```

Every store total has the shape `R$ 9,99` with one, two or three digits before the comma. **That is
good news and a warning.** Good, because there is only one format to convert: strip `R$ `, turn the
comma into a point. A warning, because no sale reached R$ 1,000 in 2025, so the till's thousands
separator — a point, as in `R$ 1.234,56` — never appears, and a conversion written and tested
against this year's data would mangle the first large sale next year. Lesson 7 writes the
conversion so that it handles both.

## The profile, written down

A profile on the screen is gone when the terminal closes. **What Ana keeps is a short document**,
one line per finding, each with its number, its source and who can answer for it:

| finding | how many | where it comes from | who can answer |
|---|---|---|---|
| `store_sales.csv` is Latin-1 with `;` | one file | the shops' till | nobody needs to: read it correctly |
| product codes without leading zeros | some rows | the app | the app team |
| repeated customer ids | 37 extra rows | the CRM export | the CRM team |
| birth year 1900 | 348 | the shops' form | the shops' manager |
| seven-digit CEPs | 288 | the app | the app team |
| dates day-first and month-first | 1,369 rows | the shops and the app | the app team |
| blank and `0` both mean no discount | 13,883 and 11,233 | the website and the app | nobody needs to: same meaning |
| negative totals | 137 | the website's coupons | payments |
| marketing consent written 10 ways | 2,352 filled | all three systems | the CRM team |

**The last column is the reason to write it down.** Some findings are cleaned and forgotten; some
are questions only another team can answer, and the best fix for a seven-digit CEP is an app that
stores it as text. Lesson 17 keeps this document beside the cleaning code, so that the next person
can tell a decision from an accident.
