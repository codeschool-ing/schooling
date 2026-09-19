---
title: LEFT JOIN, and the rows that were disappearing
version: 1
---

Célia has never ordered. An inner join leaves her out, and nothing says so.

Most of the time that is wrong, because the questions people actually ask are about everybody:

- *How much has each customer spent?* — Célia has spent zero, and zero is an answer.
- *Which products have never sold?* — a question entirely about rows with no partner.
- *Show every order with its shipment* — orders not yet shipped are the ones somebody is looking
  for.

```sql
SELECT c.name, o.id, o.total
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id;
```

```
 name       | id   | total
------------+------+-------
 Ana Lopes  | 1001 | 34.90
 Ana Lopes  | 1003 | 51.00
 Ana Lopes  | 1004 | 34.90
 Bruno Sá   | 1002 | 69.80
 Célia Reis | NULL | NULL
```

Five rows. **Every row of the left table appears at least once**; where there is no partner, the
right-hand columns are filled with `NULL`.

## What `LEFT` means, exactly

> **Keep every row of the left table. Pair it where you can. Where you cannot, invent one pair with
> nulls on the right.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The same three customers and four orders. Curved lines pair three orders with Ana and one with Bruno. Célia's box is lit like the others, and a dashed line leads from her to a pair of nulls. On the right, the result holds five rows: Ana three times, Bruno once, and Célia once with null in both order columns.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">customers c  LEFT JOIN  orders o  ON o.customer_id = c.id</text><text x=\"14\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">customers</text><rect x=\"14\" y=\"56\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1  Ana Lopes</text><rect x=\"14\" y=\"88\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2  Bruno Sá</text><rect x=\"14\" y=\"120\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"133\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3  Célia Reis</text><text x=\"300\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orders</text><rect x=\"300\" y=\"56\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1001  Ana    34.90</text><rect x=\"300\" y=\"82\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1003  Ana    51.00</text><rect x=\"300\" y=\"108\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"120\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1004  Ana    34.90</text><rect x=\"300\" y=\"134\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"146\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1002  Bruno  69.80</text><path d=\"M164 69 C204 69 260 68 300 68\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 69 C204 69 260 94 300 94\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 69 C204 69 260 120 300 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 101 C204 101 260 146 300 146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 133 C204 133 260 173 300 173\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"308\" y=\"173\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">NULL   NULL</text><text x=\"506\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">result</text><rect x=\"506\" y=\"56\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1001  34.90</text><rect x=\"506\" y=\"80\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1003  51.00</text><rect x=\"506\" y=\"104\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1004  34.90</text><rect x=\"506\" y=\"128\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno Sá    1002  69.80</text><rect x=\"506\" y=\"152\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"162\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Célia Reis  NULL  NULL</text><text x=\"14\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Five rows. Every customer appears at least once; where there is no partner, the right-hand columns are null.</text></svg>", "caption": "The dashed line is the pair the database invents so that Célia has one. It is the whole of what LEFT means."}
```

`LEFT OUTER JOIN` is the full spelling; `OUTER` is optional and almost nobody writes it.

**The sides now mean different things**, which is the difference from an inner join:

```sql
FROM customers c LEFT JOIN orders o ON …    -- every customer, orders where there are some
FROM orders o LEFT JOIN customers c ON …    -- every order, customers where there are some
```

Those are different queries. The first keeps Célia; the second keeps order 1005, the guest checkout
with no customer. Which one you want depends on the question, and getting it backwards produces a
result that looks fine and answers something else.

The habit: **put the table the question is about on the left.**

## The nulls it creates are not in the data

This catches everybody once. `o.total` is `NOT NULL` in the table — lesson 3 declared it — and here
it is, null.

The null was not read from anywhere. **The join invented it**, because there was no row to take a
value from. Which means every rule from lesson 1 applies to it:

```sql
SELECT c.name, sum(o.total) FROM customers c LEFT JOIN orders o ON … GROUP BY c.name;
```

Célia's sum is `NULL`, not `0` — because `sum` of nothing is unknown rather than zero. Almost
always what you want to show is zero:

```sql
SELECT c.name, coalesce(sum(o.total), 0) AS spent
FROM   customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.name;
```

And the count needs care for the same reason:

```sql
count(*)        -- 1 for Célia: there is one row, the invented one
count(o.id)     -- 0 for Célia: the column is null and count ignores nulls
```

**`count(*)` after a `LEFT JOIN` is almost always the bug.** It counts rows, and Célia has a row.
`count(o.id)` counts orders, which is what somebody meant. This is the single most useful thing to
remember about counting after an outer join.

## Reading one

When you see a `LEFT JOIN`, three questions:

1. **Which table is the left one?** That is the set of rows the answer is about.
2. **Which columns can now be null that were not before?** Every column of the right-hand side.
3. **Does anything downstream treat those nulls correctly?** The `count(*)`, the `sum`, the `WHERE`
   — each has a rule from lesson 1 and each of them applies.

That third question is the whole of the next section, because there is one place a condition can go
that turns a `LEFT JOIN` back into an inner one without saying so.
