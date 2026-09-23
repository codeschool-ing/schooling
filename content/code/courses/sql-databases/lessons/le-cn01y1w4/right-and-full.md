---
title: RIGHT and FULL, briefly and with a recommendation
version: 2
---

## RIGHT JOIN

Keeps every row of the **right** table instead of the left:

```sql
SELECT c.name, o.id
FROM   customers c
RIGHT JOIN orders o ON o.customer_id = c.id;
```

Every order appears, including 1005 with no customer, and its `c.name` is null.

**It is exactly a `LEFT JOIN` with the tables swapped**, and the swap is the recommendation:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 192\" role=\"img\" aria-label=\"Two highlighted boxes at the top: Célia Reis, a customer with no order, and order 1005, which has no customer. Below them, four panels — JOIN, LEFT JOIN, RIGHT JOIN and FULL JOIN — each saying what it does with the two. JOIN drops both. LEFT JOIN keeps Célia and drops 1005. RIGHT JOIN drops Célia and keeps 1005. FULL JOIN, drawn highlighted, keeps both.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Célia has no order. Order 1005 has no customer. The four joins differ only in what they do with those two.</text><rect x=\"14\" y=\"34\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">3  Célia Reis</text><text x=\"176\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">left orphan</text><rect x=\"400\" y=\"34\" width=\"150\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"410\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">1005   —   12.00</text><text x=\"562\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">right orphan</text><rect x=\"14\" y=\"76\" width=\"164\" height=\"78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"96\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">JOIN</text><text x=\"28\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Célia</text><text x=\"164\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">dropped</text><text x=\"28\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1005</text><text x=\"164\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">dropped</text><rect x=\"190\" y=\"76\" width=\"164\" height=\"78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">LEFT JOIN</text><text x=\"204\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Célia</text><text x=\"340\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">kept</text><text x=\"204\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1005</text><text x=\"340\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">dropped</text><rect x=\"366\" y=\"76\" width=\"164\" height=\"78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"448\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">RIGHT JOIN</text><text x=\"380\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Célia</text><text x=\"516\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--paper-dim)\">dropped</text><text x=\"380\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1005</text><text x=\"516\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">kept</text><rect x=\"542\" y=\"76\" width=\"164\" height=\"78\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"624\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">FULL JOIN</text><text x=\"556\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Célia</text><text x=\"692\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">kept</text><text x=\"556\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1005</text><text x=\"692\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">kept</text><text x=\"14\" y=\"176\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">RIGHT is LEFT with the tables swapped, which is why the recommendation is to swap them and write LEFT.</text></svg>", "caption": "The only difference between the four is which orphan survives. Everything else about them is the same join."}
```

```sql
FROM orders o LEFT JOIN customers c ON c.id = o.customer_id
```

Same rows, same answer, and it reads in the direction the query is about — *every order, with its
customer where there is one.*

> **Write `LEFT JOIN`. Swap the tables instead of reaching for `RIGHT`.**

Not because `RIGHT` is broken, but because a reader scanning a query builds a picture from the top
down, and a `RIGHT JOIN` three tables in means the thing the query is about is somewhere further
down the list rather than at the start. Mix the two in one query and almost nobody can say what the
result set is without working it out on paper.

You will still meet it — usually in a query that grew a table at a time — and recognising it is the
whole of what you need.

## FULL OUTER JOIN

Keeps everything from both sides:

```sql
SELECT c.name, o.id
FROM   customers c
FULL JOIN orders o ON o.customer_id = c.id;
```

```
 name       | id
------------+------
 Ana Lopes  | 1001
 Ana Lopes  | 1003
 Ana Lopes  | 1004
 Bruno Sá   | 1002
 Célia Reis | NULL    <- a customer with no order
 NULL       | 1005    <- an order with no customer
```

Both kinds of orphan, in one result. It is genuinely rare in application code and genuinely useful
for one job: **reconciliation**.

```sql
SELECT coalesce(a.reference, b.reference) AS reference,
       a.amount AS ours,
       b.amount AS theirs
FROM   our_ledger   a
FULL JOIN their_statement b ON b.reference = a.reference
WHERE  a.reference IS NULL          -- only they have it
   OR  b.reference IS NULL          -- only we have it
   OR  a.amount <> b.amount;        -- both have it and they disagree
```

That is the query for *"what do these two systems disagree about"*, and it finds all three kinds of
disagreement at once. Every finance system, every import, every migration eventually needs it.

Note the `coalesce` on the first column: either side can be null, so neither alone gives you the
reference.

## Which to use, as one table

| you want | write |
|---|---|
| only rows that pair | `JOIN` |
| every row of the table the question is about | `LEFT JOIN`, with that table first |
| every row of the other one | swap the tables and use `LEFT JOIN` |
| both sets of orphans | `FULL JOIN` |
| every pair, deliberately | `CROSS JOIN` — the `the-other-joins` section |

In practice, over a career: a large majority `JOIN`, a substantial minority `LEFT JOIN`, `FULL JOIN`
a handful of times, and `RIGHT JOIN` mostly when reading somebody else's code.

## MySQL has no FULL JOIN

Worth knowing before lesson 12, because it is the one gap people hit:

```sql
SELECT … FROM a LEFT JOIN b ON …
UNION
SELECT … FROM a RIGHT JOIN b ON …;
```

A left join and a right join, unioned — `UNION` rather than `UNION ALL`, because the paired rows
appear in both halves and the duplicates have to go. It works, it is slower, and it is the standard
workaround. SQLite gained `FULL JOIN` in 2022; MariaDB still has not.
