---
title: Writing the definition down
version: 1
---

A definition that lives in somebody's head, or in a query on somebody's laptop, is not shared. It
has to be written where people look, and it has two readers with different needs: a person, who
wants the meaning in a sentence, and a tool, which wants the arithmetic in SQL.

## For people: the card

The form most teams converge on is a short card per metric. Lantern's net revenue:

| field | value |
|---|---|
| name | Net revenue |
| question it answers | how much money arrived from customers and stayed? |
| formula | `sum(net_cents)` from `order_revenue` |
| filter | `status = 'paid'`; customer 1 excluded (the shop's test account) |
| time | order date, São Paulo days |
| grain it can be shown at | day, and anything coarser |
| owner | finance |
| known caveats | 14 August 2025 is missing; refunds are known only once they happen, so a recent month can still fall |
| since | 18 June 2026 |

**The caveats row is the one most cards leave out and most readers need.** It is where lesson 1's
findings go, so that the person reading a chart of August 2025 learns about the missing day from
the definition rather than from a decision made on the wrong number. The last caveat is worth
reading twice: a revenue figure for last week will go down as refunds arrive, which is not an
error, and a definition that says so saves somebody from reporting one.

## For tools: in the database itself

PostgreSQL can store a description on any table, view or column, and every client that lists the
database's objects shows it — `psql`, and Metabase from lesson 3:

```sql
COMMENT ON VIEW order_revenue IS
'One row per order, values in cents.
net_cents is gross_cents minus the order''s discount.
Net revenue: sum(net_cents) where status = ''paid'', without customer 1,
by order date in America/Sao_Paulo. Owner: finance. Since 2026-06-18.';
```

```
lantern=# COMMENT ON VIEW order_revenue IS
lantern-# 'One row per order, values in cents.
lantern'# net_cents is gross_cents minus the order''s discount.
lantern'# Net revenue: sum(net_cents) where status = ''paid'', without customer 1,
lantern'# by order date in America/Sao_Paulo. Owner: finance. Since 2026-06-18.';
COMMENT
```

The doubled quotes are how a single quote is written inside a string in SQL. Reading it back:

```
lantern=# SELECT obj_description('order_revenue'::regclass) AS definition;
                               definition                               
------------------------------------------------------------------------
 One row per order, values in cents.                                   +
 net_cents is gross_cents minus the order's discount.                  +
 Net revenue: sum(net_cents) where status = 'paid', without customer 1,+
 by order date in America/Sao_Paulo. Owner: finance. Since 2026-06-18.
(1 row)
```

The `+` at the end of a line is how `psql` shows a line break inside a value. A comment travels with
the view: whoever opens the database finds the definition beside the arithmetic, and a change to
one is made where the other sits. It is not a full catalogue — `data-governance` covers those —
but it costs one statement, and lesson 3 builds on it.
