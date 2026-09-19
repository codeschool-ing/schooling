---
title: INNER JOIN, the one you write most
version: 1
---

```sql
SELECT c.name, o.id, o.total
FROM   customers c
INNER JOIN orders o ON o.customer_id = c.id;
```

`INNER` is the default, so almost nobody writes it:

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
```

**Only pairs that satisfy the condition survive.** A row on either side with no partner is not in
the result, and nothing says so.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Three customers on the left — Ana, Bruno and Célia — and four orders on the right. Curved lines pair each order with its customer: three reach Ana and one reaches Bruno. Célia's box is drawn dim and has no line at all. On the right, the result holds four rows: Ana three times and Bruno once. Célia is absent from it.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">customers c  JOIN  orders o  ON o.customer_id = c.id</text><text x=\"14\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">customers</text><rect x=\"14\" y=\"56\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"69\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1  Ana Lopes</text><rect x=\"14\" y=\"88\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2  Bruno Sá</text><rect x=\"14\" y=\"120\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"24\" y=\"133\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3  Célia Reis</text><text x=\"300\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orders</text><rect x=\"300\" y=\"56\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1001  Ana    34.90</text><rect x=\"300\" y=\"82\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1003  Ana    51.00</text><rect x=\"300\" y=\"108\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"120\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1004  Ana    34.90</text><rect x=\"300\" y=\"134\" width=\"168\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"308\" y=\"146\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1002  Bruno  69.80</text><path d=\"M164 69 C204 69 260 68 300 68\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 69 C204 69 260 94 300 94\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 69 C204 69 260 120 300 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M164 101 C204 101 260 146 300 146\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"506\" y=\"42\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">result</text><rect x=\"506\" y=\"56\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1001  34.90</text><rect x=\"506\" y=\"80\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"90\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1003  51.00</text><rect x=\"506\" y=\"104\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Ana Lopes   1004  34.90</text><rect x=\"506\" y=\"128\" width=\"200\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"514\" y=\"138\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bruno Sá    1002  69.80</text><text x=\"14\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Four pairs, four rows. Célia has no partner, so she is not here — and nothing says so.</text></svg>", "caption": "A pair survives or it is not in the result. Célia is dropped in silence, which is what the next two sections are about."}
```

## The aliases are not decoration

```sql
SELECT c.name, o.id
FROM   customers c
JOIN   orders o ON o.customer_id = c.id;
```

Both tables have `id`. Writing `SELECT id` is an error — *column reference "id" is ambiguous* — and
that error is the good case. The bad case is two tables where only one has the column today, so the
unqualified name works, and somebody adds that column to the other table next year. The query is
still valid and now reads the wrong one.

> **Qualify every column in a join. Even the unambiguous ones.**

And the aliases make it readable: `c` and `o` in a two-table query, meaningful short names in a
five-table one. `customers AS c` is the standard spelling and `customers c` is the same thing.

## The old syntax, and why it is worth recognising

You will meet this in existing code:

```sql
SELECT c.name, o.id
FROM   customers c, orders o
WHERE  o.customer_id = c.id;
```

A comma between tables means every pair, and the `WHERE` then throws most of them away. It produces
the same answer as the explicit join above and it is worse in two ways:

- **The join condition and the filters are mixed together.** Reading a five-table query in this
  style, you cannot tell at a glance which conditions connect the tables and which select rows.
- **Forgetting one is not an error.** Leave out `WHERE o.customer_id = c.id` and you get every
  customer paired with every order — three times five rows here, and three million times five
  million on a real system. The query runs, returns nonsense, and takes the database with it.

Explicit `JOIN … ON` cannot be forgotten in the same way: the `ON` is part of the syntax. Use it.

## An inner join is symmetric

```sql
FROM customers c JOIN orders o ON o.customer_id = c.id
FROM orders o JOIN customers c ON c.id = o.customer_id
```

Same rows, same answer. Nothing about `INNER JOIN` prefers one side, so which table you put first is
a readability decision — start with the thing the query is *about*, and join what decorates it.

**This stops being true for `LEFT JOIN`**, where the sides mean different things. That is the next
section but one, and it is the reason people who learned joins as "combining tables" get stuck.

## The condition can be anything, and usually is not

Almost every join you write will be an equality on a foreign key:

```sql
ON o.customer_id = c.id
```

That is not a rule of SQL; it is what a normalised schema makes natural, and it is worth noticing
that lessons 1 and 2 were building towards exactly this. A table with a list in a cell, or a
repeated name instead of a reference, cannot be joined on — which is the practical cost of the
shapes those lessons refused.

When the condition is something else, it is worth a comment:

```sql
-- a price valid at the time of the order, not the current one
JOIN price_history p
  ON p.product_id = l.product_id
 AND o.ordered_on BETWEEN p.valid_from AND p.valid_to
```

That is a range join, it is a real pattern, and it is also where the multiplication in the next
section bites hardest — if two rows of `price_history` overlap, every order in the overlap is
counted twice, and nothing refuses it.
