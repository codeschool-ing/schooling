---
title: The multiplication, which is where the wrong answers come from
version: 1
---

This is the most important section in the lesson, and it is about counting.

Ana has three orders. Join `customers` to `orders` and **Ana's row appears three times**. Her name,
her email, her city — three copies, in three rows of the result.

That is correct. It is what "one row per pair" means. And it is the source of almost every wrong
number in SQL, because the moment you count or total those rows, you are counting Ana three times.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"On the left, a customers table with three rows: Ana, Bruno and Celia. In the middle, an orders table with four rows, three belonging to Ana and one to Bruno. On the right, the joined result: four rows, in which Ana's name appears three times and Bruno's once, while Celia does not appear at all. A note reads: three customers went in and four rows came out.\"><text x=\"14\" y=\"24\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">customers</text>\n<rect x=\"14\" y=\"32\" width=\"124\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"24\" y=\"45\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1  Ana</text>\n<rect x=\"14\" y=\"58\" width=\"124\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"24\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2  Bruno</text>\n<rect x=\"14\" y=\"84\" width=\"124\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"24\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3  Celia</text>\n<text x=\"14\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3 rows</text>\n<text x=\"250\" y=\"24\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">orders</text>\n<rect x=\"250\" y=\"32\" width=\"150\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"260\" y=\"45\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1001  c=1  34.90</text>\n<rect x=\"250\" y=\"58\" width=\"150\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"260\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1002  c=2  69.80</text>\n<rect x=\"250\" y=\"84\" width=\"150\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"260\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1003  c=1  51.00</text>\n<rect x=\"250\" y=\"110\" width=\"150\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"260\" y=\"123\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1004  c=1  34.90</text>\n<text x=\"250\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 rows</text>\n<text x=\"520\" y=\"24\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the join</text>\n<rect x=\"520\" y=\"32\" width=\"186\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"530\" y=\"45\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana    1001   34.90</text>\n<rect x=\"520\" y=\"58\" width=\"186\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"530\" y=\"71\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana    1003   51.00</text>\n<rect x=\"520\" y=\"84\" width=\"186\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"530\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Ana    1004   34.90</text>\n<rect x=\"520\" y=\"110\" width=\"186\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"530\" y=\"123\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bruno  1002   69.80</text>\n<text x=\"520\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">4 rows, and Ana is in three</text>\n<path d=\"M144 45 L244 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M236 40 L244 45 L236 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path>\n<path d=\"M406 72 L514 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M506 67 L514 72 L506 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path>\n<line x1=\"14\" y1=\"184\" x2=\"706\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n<text x=\"14\" y=\"208\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">What each count means afterwards</text>\n<text x=\"14\" y=\"232\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">count(*)</text><text x=\"200\" y=\"232\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">4</text><text x=\"240\" y=\"232\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pairs, not customers and not orders</text>\n<text x=\"14\" y=\"254\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">count(DISTINCT c.id)</text><text x=\"200\" y=\"254\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">2</text><text x=\"240\" y=\"254\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">customers who ordered — Celia is absent</text>\n<text x=\"14\" y=\"276\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sum(c.credit_limit)</text><text x=\"200\" y=\"276\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">wrong</text><text x=\"280\" y=\"276\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ana&#39;s limit is added three times</text>\n</svg>", "caption": "Three customers and four orders produce four rows. Ana is in three of them, so any total over a customer column counts her three times."}
```

## The wrong answers it produces

**Counting.**

```sql
SELECT count(*) FROM customers c JOIN orders o ON o.customer_id = c.id;
```

Four. Not the number of customers, which is 3, and not the number who ordered, which is 2. It is the
number of **pairs**, and that is rarely the question anybody asked.

**Totalling a column of the one-sided table.**

```sql
SELECT sum(c.credit_limit) FROM customers c JOIN orders o ON o.customer_id = c.id;
```

Ana's credit limit is added three times. The number is meaningless and looks completely ordinary,
which is why nobody catches it by eye. This is the version that reaches a board report.

**And `DISTINCT` hiding it**, which lesson 4 warned about and here is where it happens:

```sql
SELECT DISTINCT c.name FROM customers c JOIN orders o ON o.customer_id = c.id;
```

Two rows, correct answer, and the defect is still there — the query built four rows and then threw
one away. Add one column and it comes back. Add a `count(*)` and `DISTINCT` cannot save it at all.

## Fan-out is a property of the relationship

Whether a join multiplies is decided by which side is "many", and lesson 1 gave you the tool:

| join | rows per left-hand row |
|---|---|
| a many-to-one, on the foreign key — `orders` to `customers` | exactly one |
| a one-to-many — `customers` to `orders` | as many as there are |
| through a join table — `orders` to `products` | one per line |
| two one-to-manys from the same table | **the product of both**, and this is the nasty one |

That last row deserves its own demonstration, because it is the join bug that survives review:

```sql
SELECT o.id, sum(l.quantity), sum(p.amount)
FROM   orders o
JOIN   order_lines l ON l.order_id = o.id
JOIN   payments    p ON p.order_id = o.id
GROUP BY o.id;
```

An order with 3 lines and 2 payments produces **six** rows. Every quantity is counted twice and
every payment three times. Both totals are wrong, neither is obviously wrong, and the query reads
perfectly.

## What to do about it

**Know what one row of your result is**, and say it out loud. *"One row per order per line per
payment"* makes the problem audible before you run anything.

**Aggregate each side separately** rather than joining both and hoping. Lesson 7's subqueries are
the tool, and the shape is:

```sql
SELECT o.id, l.total_quantity, p.total_paid
FROM   orders o
LEFT JOIN (SELECT order_id, sum(quantity) AS total_quantity FROM order_lines GROUP BY order_id) l
       ON l.order_id = o.id
LEFT JOIN (SELECT order_id, sum(amount)   AS total_paid     FROM payments    GROUP BY order_id) p
       ON p.order_id = o.id;
```

Each subquery produces **one row per order**, so neither multiplies the other. It is longer and it
is right.

**And check the count before you trust the number.** `SELECT count(*)` on the joined query, against
the count of the table you think you are reporting on. If they differ and you did not expect them
to, the multiplication is why.
