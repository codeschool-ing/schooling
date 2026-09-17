---
title: GROUP BY, and the rule about which columns you may select
version: 1
---

`GROUP BY` sorts the rows into piles and runs the aggregates once per pile.

```sql
SELECT   customer_id, count(*) AS orders, sum(total) AS spent
FROM     orders
GROUP BY customer_id;
```

One row per customer who has an order. The thousand orders are gone: you have the totals and you no
longer have the orders, and that trade is the whole character of `GROUP BY`. The next half of this
lesson is the other tool, which does not make it.

## The rule

> **Every column in `SELECT` must either appear in `GROUP BY` or be inside an aggregate.**

It is not an arbitrary restriction. Ask for `o.total` beside `count(*)` grouped by customer and you
have asked the database for *one* total out of the three the pile contains, without saying which.
There is no answer, so there is an error:

```
ERROR:  column "o.total" must appear in the GROUP BY clause
        or be used in an aggregate function
```

That message is one of the most useful in SQL, because it always means the same thing: **you asked
for a detail of a group that has more than one of it.** Decide which you wanted — `max(total)`, or
`sum(total)`, or the column added to `GROUP BY` so the piles get smaller.

MySQL spent years not enforcing this. Older configurations would pick a value from an arbitrary row
and return it without comment, which meant a query that looked correct returned one customer's
total against another customer's date. `ONLY_FULL_GROUP_BY` is on by default from MySQL 5.7 onward
and the behaviour now matches everyone else, but you will still meet queries written under the old
rules, and they are not safe to trust.

PostgreSQL allows one useful relaxation: group by a table's **primary key** and you may select any
column of that table, because the key already determines them.

```sql
SELECT   c.id, c.name, c.email, count(o.id)
FROM     customers c LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id;
```

`c.name` and `c.email` are legal here — one customer id is one customer, so there is no ambiguity
to resolve. It saves listing every column you want to display. MySQL 8 does the same analysis;
SQLite does not complain about anything at all, which is not the same as being right.

## Grouping by more than one thing

```sql
SELECT   customer_id, status, count(*)
FROM     orders
GROUP BY customer_id, status;
```

The pile is now the **combination**: one row per customer per status. Adding a column to `GROUP BY`
always makes the groups smaller and the result longer, and that is the dial you turn when a summary
is too coarse.

The order of the columns in `GROUP BY` does not matter — it is a set, not a sequence. The order of
the rows that come out is undefined without an `ORDER BY`, exactly as lesson 4 said.

## Grouping by an expression

The group does not have to be a column, and this is how every time series you will ever build gets
made:

```sql
SELECT   date_trunc('month', placed_at) AS month, sum(total)
FROM     orders
GROUP BY date_trunc('month', placed_at)
ORDER BY month;
```

Revenue per month, from a table that knows nothing about months. The same shape gives you per week,
per day, per hour. Other engines spell the truncation differently — MySQL's `DATE_FORMAT(placed_at,
'%Y-%m')`, SQLite's `strftime('%Y-%m', placed_at)` — and the idea is identical.

Repeating the expression in both clauses is tiresome, and PostgreSQL, MySQL and SQLite all let you
write `GROUP BY month`, naming the output column instead. That is an extension rather than standard
SQL, so it is worth knowing it is one; every one of them also accepts `GROUP BY 1`, the position,
which is compact and becomes a silent bug the day somebody inserts a column.

## Two things that catch people

**All the nulls form one group.** Group by a nullable column and every row where it is null ends up
in the same pile, with `NULL` in the output. That is `GROUP BY` deliberately departing from `=`,
which never says two unknowns are equal — and it is what you want, but it means a row labelled
`NULL` in a report is a real group and not an error.

**A group that has no rows does not exist.** There is no row for a customer who has never ordered,
because a group is made out of rows and that customer contributed none. No amount of `GROUP BY`
will invent them; the only thing that will is a `LEFT JOIN` from the table that does have them,
which is the next section but one, and where counting stops being obvious.
