---
title: The past, overwritten
version: 1
---

Ask the shop's database what *The Salt Season IV* costs, and what it charged for it each year:

```sql
-- What the shop charged for one title, and what it says the title costs.
SELECT b.title, b.list_price_cents AS price_now,
       extract(year FROM o.ordered_at) AS year,
       min(l.unit_price_cents) AS charged_min, max(l.unit_price_cents) AS charged_max
FROM books b
JOIN order_lines l USING (book_id)
JOIN orders o      USING (order_id)
WHERE b.book_id = 2395 AND o.ordered_at < '2026-01-01'
GROUP BY 1, 2, 3 ORDER BY 3;
```

```
ana@lab:~/wh$ psql -f history.sql
       title        | price_now | year | charged_min | charged_max 
--------------------+-----------+------+-------------+-------------
 The Salt Season IV |     15990 | 2024 |       14890 |       14890
 The Salt Season IV |     15990 | 2025 |       15990 |       15990
(2 rows)
```

The book costs R$ 159.90 today. It was sold at R$ 148.90 all through 2024: prices went up on the
first of January 2025, and `books` kept the new price only. The orders survived it, because each
line wrote down the price it was charged. **A fact recorded at the moment it happened keeps its
value. A description of something keeps only its latest value.**

Prices are the easy case, because the till copied them into every line. Customers are not.
Customer 2123 lives in Londrina, in Paraná:

```
ana@lab:~/wh$ psql -c "SELECT customer_id, city, state FROM customers WHERE customer_id = 2123"
 customer_id |   city   | state 
-------------+----------+-------
        2123 | Londrina | PR
(1 row)

ana@lab:~/wh$ psql -c "SELECT changed_at, field, old_value, new_value FROM customer_changes WHERE customer_id = 2123 ORDER BY changed_at"
       changed_at       | field | old_value | new_value 
------------------------+-------+-----------+-----------
 2025-04-13 19:59:35-03 | city  | Contagem  | Londrina
 2025-04-13 19:59:35-03 | state | MG        | PR
(2 rows)
```

The customer lived in Contagem, in Minas Gerais, until the 13th of April 2025. Every order they
placed before that was placed by somebody in Minas Gerais. Ask the operational database for
"sales in 2024 by the customer's state" and it joins those orders to `customers`, finds `PR`, and
counts them in Paraná.

How many orders does that move?

```
ana@lab:~/wh$ psql -c "SELECT count(*) AS orders_2024, count(DISTINCT o.customer_id) AS customers FROM orders o JOIN customer_changes c USING (customer_id) WHERE c.field = 'state' AND o.ordered_at < '2025-01-01' AND c.changed_at >= '2025-01-01'"
 orders_2024 | customers 
-------------+-----------
        1404 |       196
(1 row)
```

**1,404 orders from 2024, by 196 customers, are counted in a state they were not in when they
bought.** Nothing errors and nothing looks wrong; the total for Brazil is right and the split by
state is not. This shop happens to log every change in `customer_changes`, so the history *could*
be rebuilt. Most operational databases keep no such log, and then it cannot.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A timeline of customer 2123 from January 2024 to December 2025. Until 13 April 2025 the customer lived in Contagem, Minas Gerais; after it, in Londrina, Paraná. The operational database keeps only Londrina, so every order placed before the move is counted in Paraná when sales are split by the customer&#x27;s state.\"><text x=\"40\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">what happened</text><rect x=\"40\" y=\"36\" width=\"410.6666666666667\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"245.33333333333334\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Contagem, MG</text><rect x=\"450.6666666666667\" y=\"36\" width=\"229.33333333333331\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"565.3333333333334\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Londrina, PR</text><line x1=\"450.6666666666667\" y1=\"30\" x2=\"450.6666666666667\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"450.6666666666667\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">moved, 13 April 2025</text><text x=\"40\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">what the customers table says</text><rect x=\"40\" y=\"116\" width=\"640\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Londrina, PR — for every order, before and after</text><line x1=\"40.0\" y1=\"192\" x2=\"40.0\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"40.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2024</text><line x1=\"360.0\" y1=\"192\" x2=\"360.0\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"360.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2025</text><line x1=\"680.0\" y1=\"192\" x2=\"680.0\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"680.0\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2026</text><line x1=\"40\" y1=\"196\" x2=\"680\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line></svg>", "caption": "Customer 2123 over two years. The operational row keeps the latest city, so every earlier order inherits it."}
```

**Keeping the past is the warehouse's job, because it is nobody else's.** The operational database
is right to overwrite: the till needs to ship to where the customer lives now. Lesson 5 is entirely
about how a warehouse keeps both answers: where the customer lived then, and where they live now.
