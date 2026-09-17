---
title: Window functions, which summarise without collapsing
version: 1
---

Everything so far destroys the rows it summarises. Group by customer and the orders are gone; you
have the totals and nothing else. That is usually what you want, and it makes a whole class of
question impossible to ask.

*"Show me each order, and beside it how much that customer has spent in total."*

There is no `GROUP BY` for that, because the answer has one row per order **and** a number computed
over the customer's whole pile. Before window functions existed you wrote a correlated subquery per
column, or you ran a second query and joined the results by hand. Now it is one word:

```sql
SELECT id, customer_id, total,
       sum(total) OVER (PARTITION BY customer_id) AS customer_total
FROM   orders;
```

Every order comes back. Beside each one is its customer's total.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three tables side by side over the same four orders, two for Ana and two for Bruno. The first is the orders themselves, four rows. The second is the result of GROUP BY customer, two rows holding only the totals. The third is the result of the same sum written with OVER PARTITION BY, four rows, each original order carrying its customer total beside it. Below, a band contrasts the two: GROUP BY gives one row per group and the individual order can no longer be seen, while OVER keeps every row and gives each one its group number, which is what lets a row be compared with its own group in a single query.\"><text x=\"14\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">orders</text>\n<rect x=\"14\" y=\"30\" width=\"170\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"24\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     34.90</text>\n<rect x=\"14\" y=\"56\" width=\"170\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"24\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     51.00</text>\n<rect x=\"14\" y=\"82\" width=\"170\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"24\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   69.80</text>\n<rect x=\"14\" y=\"108\" width=\"170\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"24\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   12.00</text>\n<text x=\"14\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 rows</text>\n<text x=\"224\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">GROUP BY customer_id</text>\n<rect x=\"224\" y=\"30\" width=\"200\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"234\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     85.90</text>\n<rect x=\"224\" y=\"56\" width=\"200\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"234\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   81.80</text>\n<text x=\"224\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 rows, and the orders are gone</text>\n<text x=\"474\" y=\"22\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">OVER (PARTITION BY customer_id)</text>\n<rect x=\"474\" y=\"30\" width=\"232\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"43\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     34.90    85.90</text>\n<rect x=\"474\" y=\"56\" width=\"232\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana     51.00    85.90</text>\n<rect x=\"474\" y=\"82\" width=\"232\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   69.80    81.80</text>\n<rect x=\"474\" y=\"108\" width=\"232\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"484\" y=\"121\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno   12.00    81.80</text>\n<text x=\"474\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">4 rows, each with its total</text>\n<line x1=\"14\" y1=\"178\" x2=\"706\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"202\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">The same sum, over the same partition</text>\n<text x=\"14\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">GROUP BY</text><text x=\"200\" y=\"228\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one row per group, and no order can be seen any more</text>\n<text x=\"14\" y=\"250\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">OVER (...)</text><text x=\"200\" y=\"250\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every row survives, carrying its group number beside it</text>\n<text x=\"14\" y=\"272\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total - avg</text><text x=\"200\" y=\"272\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">which is why only the second can compare a row with its group</text>\n</svg>", "caption": "The same sum over the same partition. GROUP BY returns one row per customer and loses the orders; OVER returns every order with its customer total beside it."}
```

## `PARTITION BY` is `GROUP BY` that does not collapse

Same word for the same idea, and the only difference is what comes out:

| | rows in | rows out |
|---|---|---|
| `sum(total)` with `GROUP BY customer_id` | 1 000 | one per customer |
| `sum(total) OVER (PARTITION BY customer_id)` | 1 000 | **1 000** |

Leave the parentheses empty and the partition is the whole result:

```sql
SELECT id, total,
       sum(total)   OVER () AS grand_total,
       total * 100 / sum(total) OVER () AS percent_of_all
FROM   orders;
```

Every row now knows the total of everything, which is how you compute a share without a second
query. `count(*) OVER ()` is the same trick for "how many rows are there altogether", and it is the
usual way to get a total row count back alongside a page of results.

## The question it really unlocks

Anything of the form *"compared with"*:

```sql
SELECT id, customer_id, total,
       avg(total) OVER (PARTITION BY customer_id)         AS usual,
       total - avg(total) OVER (PARTITION BY customer_id) AS versus_usual
FROM   orders;
```

Each order against that customer's own average. A `GROUP BY` cannot express this at all, because
one of the two numbers is a property of the row and the other is a property of the group — and a
`GROUP BY` query has no rows left to hold the first one.

Any aggregate works this way. `count`, `sum`, `avg`, `min`, `max`, `string_agg` — put `OVER` after
it and it stops collapsing.

## Where it runs, which decides where you may write it

Extend lesson 4's running order by one step:

```
FROM → WHERE → GROUP BY → HAVING → window functions → SELECT → ORDER BY → LIMIT
```

Two consequences, and the second is the one everybody hits.

**Window functions see the rows that survived `WHERE` and `HAVING`.** A `WHERE customer_id = 7`
makes `sum(total) OVER ()` the total for customer 7, not the total for everybody. The partition is
computed over what is left, never over the table.

**And you cannot filter on a window function.**

```sql
SELECT id, total, rank() OVER (ORDER BY total DESC) AS r
FROM   orders
WHERE  r <= 10;                      -- ERROR: column "r" does not exist
```

When `WHERE` runs, no window function has run. Neither `WHERE` nor `HAVING` can help, because both
are already finished. The answer is to compute it in one query and filter outside it:

```sql
SELECT * FROM (
    SELECT id, total, rank() OVER (ORDER BY total DESC) AS r FROM orders
) t
WHERE t.r <= 10;
```

That wrapping is not a workaround for a missing feature — it is the running order, made visible.
Lesson 7 gives it the tidier `WITH` syntax, and you will write this shape constantly.

## Windows over aggregates

Both halves of the lesson in one query, which is legal and reads like a mistake:

```sql
SELECT   customer_id,
         sum(total)                  AS spent,
         sum(sum(total)) OVER ()     AS everyone,
         sum(total) * 100 / sum(sum(total)) OVER () AS percent
FROM     orders
GROUP BY customer_id;
```

`sum(sum(total))` is not a typo. The inner `sum` is the aggregate, run per group; the outer one is a
window function, run over the grouped rows — because windows come **after** grouping, and by then
one row per customer is all there is. Each customer's share of the whole, in one pass.

## Naming a window you use more than once

Repeating a long `OVER (…)` three times is how they get out of step. Name it instead:

```sql
SELECT   customer_id, total,
         avg(total) OVER w,
         min(total) OVER w,
         max(total) OVER w
FROM     orders
WINDOW   w AS (PARTITION BY customer_id);
```

The `WINDOW` clause sits between `HAVING` and `ORDER BY`. PostgreSQL, MySQL 8 and SQLite have it;
it changes nothing about the result and it means one definition instead of three.
