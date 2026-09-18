---
title: The same questions on MySQL and SQLite
version: 1
---

Everything above is PostgreSQL's output, because it is the most detailed of the four engines in
this course and the habits it teaches carry over. The other engines answer the same questions in
their own shapes, and this section is the translation table. Lesson 12 compares the engines as a
whole; this is only the plan.

## MySQL and MariaDB

`EXPLAIN` in front of a query prints a **table, one row per table the query touches**, rather than
a tree. The columns to read:

| column | what it says | the PostgreSQL equivalent |
|---|---|---|
| `type` | how the table is accessed: `ALL` is a full scan, `ref` and `range` use an index, `eq_ref` is a lookup by unique key, `const` is a single row | the scan node |
| `key` | which index was chosen, or `NULL` | `Index Scan using …` |
| `rows` | the estimated rows examined | `rows=` in the estimate |
| `Extra` | what else happened: `Using where` is a `Filter`; `Using index` is an index-only scan; `Using filesort` is a `Sort`; `Using temporary` is a hash or a materialisation | the detail lines |

The row order is the join order: the first row is the driving table and each row below it is
joined to what came before, so a plan reads top to bottom the way a nested loop runs. `type: ALL`
on any row but the first is the missing-index shape from the joins section — the whole table read
once per outer row.

`Using filesort` is the line people misread. It does not mean the sort went to disk; it means a
sort happened at all, in memory or not, because no index supplied the order. It is the MySQL
spelling of "a `Sort` node with no index under it", and the fix is the same.

**`EXPLAIN ANALYZE`** exists in MySQL 8.0.18 and later, and it prints a **tree**, in text, with
actual times and row counts — closer to PostgreSQL's output than MySQL's own tabular one. On a
version that has it, prefer it for the same reason as in the rest of this lesson: the estimate is a
prediction, and the actual is what happened.

Finding the slow query is the slow query log, `long_query_time`, and on 8.0 the
`performance_schema` tables summarised by `sys.statement_analysis` — the same two tools as the
first section, and the same rule about totals against means.

## SQLite

```sql
EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 42;
```

`EXPLAIN` on its own prints the bytecode SQLite will execute, which is not what anybody wants.
`EXPLAIN QUERY PLAN` prints one line per step:

```
EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 42;
  SCAN orders

EXPLAIN QUERY PLAN SELECT * FROM customers WHERE email = 'user42@example.com';
  SEARCH customers USING INDEX sqlite_autoindex_customers_1 (email=?)

CREATE INDEX orders_customer_id_idx ON orders (customer_id);
EXPLAIN QUERY PLAN SELECT * FROM orders WHERE customer_id = 42;
  SEARCH orders USING INDEX orders_customer_id_idx (customer_id=?)
```

`SCAN` is a full read of the table and `SEARCH … USING INDEX` is an index lookup; that pair is the
whole vocabulary, and the fix is in it. There is no `ANALYZE` variant that runs the query, and the
statistics the planner uses come from running `ANALYZE` yourself. SQLite has no autovacuum daemon
to do it, so a database that has grown a lot since it was last analysed is planning on old numbers
until somebody runs the command.

## The three questions, everywhere

| | PostgreSQL | MySQL | SQLite |
|---|---|---|---|
| which query | `pg_stat_statements`, the log | slow query log, `performance_schema` | the application's own timing |
| how is it done | `EXPLAIN` | `EXPLAIN` | `EXPLAIN QUERY PLAN` |
| what actually happened | `EXPLAIN ANALYZE` | `EXPLAIN ANALYZE` (8.0.18+) | run it, and time it |

The vocabulary changes; the method does not. Find the query with a number attached, read how the
engine intends to run it, run it for real where the engine can, and compare the two — and when
they disagree, the estimate is what is wrong.
