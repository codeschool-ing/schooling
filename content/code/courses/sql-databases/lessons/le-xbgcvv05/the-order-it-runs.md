---
title: The order you write it, and the order it runs
version: 1
---

One idea first, because it explains most of the confusing errors you will meet in the next year.

**You write the clauses in one order. The database runs them in another.**

```sql
SELECT   name, price                  -- 5. and finally, pick the columns
FROM     products                     -- 1. first, which rows exist
WHERE    price > 20                   -- 2. throw away the ones that fail
GROUP BY category                     -- 3. lesson 6
HAVING   count(*) > 1                 -- 4. lesson 6
ORDER BY price DESC                   -- 6. arrange what survived
LIMIT    10;                          -- 7. take the first few
```

The numbers are the order it actually happens. `FROM` is first because nothing can be filtered
before it is known what there is. `SELECT` — the clause you wrote first — happens near the **end**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Two columns. On the left, the clauses in the order they are written: SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY, LIMIT. On the right, the same clauses numbered in the order they run: FROM first, then WHERE, GROUP BY, HAVING, then SELECT fifth, then ORDER BY and LIMIT. Curves join each clause to its position, and the curve for SELECT is highlighted, crossing from the top of the left column down to fifth place.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The clauses you write, and the order the database runs them in.</text><text x=\"120\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">as you write it</text><text x=\"520\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">as it runs</text><rect x=\"40\" y=\"56\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">SELECT</text><rect x=\"40\" y=\"82\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"93\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">FROM</text><rect x=\"40\" y=\"108\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"119\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">WHERE</text><rect x=\"40\" y=\"134\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">GROUP BY</text><rect x=\"40\" y=\"160\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"171\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">HAVING</text><rect x=\"40\" y=\"186\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"197\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">ORDER BY</text><rect x=\"40\" y=\"212\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"120\" y=\"223\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">LIMIT</text><rect x=\"440\" y=\"56\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"67\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">1.  FROM</text><rect x=\"440\" y=\"82\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"93\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">2.  WHERE</text><rect x=\"440\" y=\"108\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"119\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">3.  GROUP BY</text><rect x=\"440\" y=\"134\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">4.  HAVING</text><rect x=\"440\" y=\"160\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"171\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">5.  SELECT</text><rect x=\"440\" y=\"186\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"197\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">6.  ORDER BY</text><rect x=\"440\" y=\"212\" width=\"160\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"520\" y=\"223\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"middle\" fill=\"var(--paper)\">7.  LIMIT</text><path d=\"M204 67 C300 67 340 171 436 171\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M204 93 C300 93 340 67 436 67\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 119 C300 119 340 93 436 93\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 145 C300 145 340 119 436 119\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 171 C300 171 340 145 436 145\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 197 C300 197 340 197 436 197\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><path d=\"M204 223 C300 223 340 223 436 223\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"14\" y=\"250\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SELECT is written first and runs fifth, which is why a name you invent there cannot be used in WHERE and can be used in ORDER BY.</text></svg>", "caption": "The one crossing line is the whole idea: SELECT is written first and computed fifth."}
```

## What that explains

Give a column a new name and try to use it:

```sql
SELECT price * 1.23 AS gross
FROM   products
WHERE  gross > 100;
```

```
ERROR:  column "gross" does not exist
LINE 3: WHERE  gross > 100;
               ^
```

`gross` is invented by `SELECT`, and `WHERE` ran before `SELECT`. When the filter was being
evaluated the name did not exist. The error is accurate and says nothing about why.

Repeat the expression instead:

```sql
SELECT price * 1.23 AS gross
FROM   products
WHERE  price * 1.23 > 100;
```

## And what is different about ORDER BY

```sql
SELECT price * 1.23 AS gross
FROM   products
ORDER BY gross DESC;
```

That works. `ORDER BY` runs **after** `SELECT`, so by the time it looks for `gross`, the name
exists.

So the rule is not "aliases never work". It is exactly:

> **An alias from `SELECT` is usable in `ORDER BY`, and not in `WHERE`, `GROUP BY` or `HAVING`.**

Which is not a quirk to memorise once you can see the order. It is the order.

## The whole sequence, once

| | clause | what it does |
|---|---|---|
| 1 | `FROM` / `JOIN` | assemble the rows to consider |
| 2 | `WHERE` | discard rows that fail a test |
| 3 | `GROUP BY` | collapse the survivors into groups |
| 4 | `HAVING` | discard whole groups |
| 5 | `SELECT` | compute the output columns, and name them |
| 6 | `ORDER BY` | arrange the result |
| 7 | `LIMIT` / `OFFSET` | take a slice of it |

Two more consequences worth having now, both of which come up in later lessons:

**`WHERE` filters rows, `HAVING` filters groups.** They are not alternatives; they run at different
moments on different things. Lesson 6.

**`LIMIT` is last**, so it takes a slice of an already-sorted result. It does not make the database
stop early in any way you can reason about — and with no `ORDER BY` it takes an arbitrary slice of
an arbitrary arrangement, which is the `limit-and-paging` section.

## It is a model, not a promise about the machine

A caution that matters from lesson 10 onwards.

The list above is the **logical** order — what the answer is defined to be. The database is free to
do the work in any order that produces the same answer, and it will: it might use an index to avoid
sorting, filter while it reads rather than afterwards, or stop reading once `LIMIT` is satisfied.

That freedom is the whole subject of the execution plan. What it never does is change the answer.
So use this order to reason about **what a query means**, and the plan in lesson 10 to reason about
**what it costs.** Confusing the two is how people end up believing that rearranging the clauses
makes a query faster, which it does not, because you did not change what you asked for.
