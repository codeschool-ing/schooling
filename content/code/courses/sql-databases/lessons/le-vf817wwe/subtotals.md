---
title: Subtotals and grand totals in one pass
version: 1
---

A report wants revenue per region per month, a line per region, and a grand total at the bottom.
That is three different groupings of the same rows, and the obvious way to get them is three
queries stapled together:

```sql
SELECT region, month, sum(total) FROM sales GROUP BY region, month
UNION ALL
SELECT region, NULL,  sum(total) FROM sales GROUP BY region
UNION ALL
SELECT NULL,   NULL,  sum(total) FROM sales;
```

It works. It also reads the table three times, and every filter has to be written three times and
stay in step for as long as the report exists. Miss one and the subtotals stop adding up to the
detail, which is the kind of defect people argue about in meetings.

## `GROUPING SETS`

The same thing, once:

```sql
SELECT   region, month, sum(total)
FROM     sales
GROUP BY GROUPING SETS ((region, month), (region), ());
```

Each parenthesised list is one grouping to compute, and `()` — the empty set — is the grand total,
the whole table as a single group. One scan, one `WHERE` clause, one place to change.

## `ROLLUP` and `CUBE`, which are shorthands

`ROLLUP` gives you a hierarchy: the full grouping, then progressively fewer columns from the right,
then the total.

```sql
GROUP BY ROLLUP (region, month)
-- the same as GROUPING SETS ((region, month), (region), ())
```

That is the shape almost every financial report wants, because it matches how they are read: detail
under a heading, headings under a bottom line. The order of the columns matters — `ROLLUP (month,
region)` subtotals by month instead.

`CUBE` gives you **every** combination:

```sql
GROUP BY CUBE (region, month)
-- (region, month), (region), (month), ()
```

Four groupings from two columns; three columns give eight. It answers "slice this any way" in one
query, and the row count grows fast enough that it is worth knowing you asked for it.

MySQL and MariaDB have the hierarchy only, with their own spelling — `GROUP BY region, month WITH
ROLLUP` — and no `GROUPING SETS` or `CUBE`. SQLite has none of the three, so there the `UNION ALL`
above is the answer.

## The ambiguity, which is the part that bites

A subtotal row has `NULL` in the columns it rolled up. So does a real group of rows whose region is
genuinely unknown. In the output they are the same character:

```
region   month     sum
south    2026-03   1400
south    NULL      3900      <- subtotal for the south
NULL     2026-03    260      <- sales whose region we do not know
NULL     NULL      9100      <- grand total
```

Row two and row four both say `NULL` for region and mean completely different things. A person
reading the table cannot tell, and neither can the program that renders it.

`GROUPING()` is the answer: it returns `1` when the column was rolled up for that row and `0` when
the null is the data's own.

```sql
SELECT   CASE WHEN GROUPING(region) = 1 THEN 'all regions' ELSE coalesce(region, 'unknown') END
           AS region,
         CASE WHEN GROUPING(month)  = 1 THEN 'all months'  ELSE to_char(month, 'YYYY-MM') END
           AS month,
         sum(total)
FROM     sales
GROUP BY ROLLUP (region, month);
```

Now every row says what it is. **Use `GROUPING()` whenever the rolled-up column is nullable** — and
if you are sure it is not nullable today, remember that `NOT NULL` is a promise somebody can drop
in a migration, and the report would go on rendering.

## Getting the rows in the right places

The output order is undefined, as always, and subtotals scattered through the detail are worse than
no subtotals. Sort by the grouping flags first, so each subtotal lands under the rows it
summarises:

```sql
ORDER BY GROUPING(region), region, GROUPING(month), month
```

`GROUPING(region)` is `0` for every detail and region line and `1` only for the grand total, which
puts the total last. Within a region, `GROUPING(month)` is `0` for the months and `1` for that
region's subtotal, which puts it under them. It reads strangely and it is exactly the sort order a
reader expects.
