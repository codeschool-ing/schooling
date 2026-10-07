---
title: The bus matrix
version: 1
---

Kimball's tool for keeping marts dependent is a table on one page, the **bus matrix**. Its rows are the business
processes the warehouse measures, each one a fact table or a family of them. Its columns are the conformed
dimensions. An `x` where they cross says that process is described by that dimension, with the same keys and the
same rows as every other process that uses it.

Ana's warehouse can draw its own matrix, because each `x` is a key column in a fact table:

```sql
-- The bus matrix, read off the warehouse itself: one row per fact table,
-- an x wherever it carries a dimension's key.
SELECT table_name AS process,
       CASE WHEN bool_or(column_name LIKE '%date_key') THEN 'x' ELSE '' END AS "date",
       CASE WHEN bool_or(column_name = 'shop_key')      THEN 'x' ELSE '' END AS shop,
       CASE WHEN bool_or(column_name = 'book_key')      THEN 'x' ELSE '' END AS book,
       CASE WHEN bool_or(column_name = 'customer_key')  THEN 'x' ELSE '' END AS customer,
       CASE WHEN bool_or(column_name = 'promotion_key') THEN 'x' ELSE '' END AS promotion,
       CASE WHEN bool_or(column_name = 'author_key')    THEN 'x' ELSE '' END AS author
FROM duckdb_columns()
WHERE schema_name = 'main' AND table_name LIKE 'fact\_%' ESCAPE '\'
GROUP BY table_name
ORDER BY table_name;
```

```
ana@lab:~/wh$ duckdb -readonly wh.duckdb < bus.sql
┌───────────────────────┬─────────┬─────────┬─────────┬──────────┬───────────┬─────────┐
│        process        │  date   │  shop   │  book   │ customer │ promotion │ author  │
│        varchar        │ varchar │ varchar │ varchar │ varchar  │  varchar  │ varchar │
├───────────────────────┼─────────┼─────────┼─────────┼──────────┼───────────┼─────────┤
│ fact_event_attendance │ x       │ x       │         │ x        │           │ x       │
│ fact_fulfilment       │ x       │         │         │ x        │           │         │
│ fact_inventory        │ x       │ x       │ x       │          │           │         │
│ fact_payments         │ x       │ x       │         │ x        │           │         │
│ fact_sales            │ x       │ x       │ x       │ x        │ x         │         │
└───────────────────────┴─────────┴─────────┴─────────┴──────────┴───────────┴─────────┘
```

Read down a column and you see what can be compared across processes. **Date runs through all five**, so any two
processes can be put on one time line. Customer runs through four, so a customer's purchases, payments, deliveries
and visits to author events can be counted together. Sales and inventory share date, shop and book, which is what lesson 3's
drilling across, months of stock per shop, rested on.

Read along a row and you see what a process can be cut by. `fact_fulfilment` has no shop: every order it follows
was shipped, and only the online shop ships, so a shop key would hold one value. An empty cell is a decision, and
the matrix makes it visible.

The matrix is also a plan. A warehouse built by Kimball's method grows one row at a time: each new process is a new
fact table, and **its dimensions are the columns that already exist**, reused rather than rebuilt. A team proposing a
new mart is asked to put it on the matrix first. If its row needs a dimension that already has a column, it uses
that column; if it needs a new one, the new column is built once, for everybody. Two marts drawn on one matrix
cannot disagree about what a customer is.

On paper the matrix is drawn before anything is built. Generated from the catalogue, as here, it shows what was
actually built, and comparing the two is a review worth doing once a year.
