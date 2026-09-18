---
title: What changes when you write SQL for Oracle
version: 1
---

Everything in lessons 4 to 7 works. The differences are specific and are the kind you meet once,
and three of them change what a query *means* rather than how it is spelled.

**Every claim in this section is documented Oracle behaviour, described rather than captured**:
there is no Oracle instance behind this course to run it on, and the rest of this lesson says so
wherever it would otherwise show output.

## The three that change meaning

**An empty string is NULL.** This is the biggest one in the language and it has no equivalent
anywhere else in this course.

```sql
INSERT INTO customers (name, email, city) VALUES ('Ana', 'ana@example.com', '');
```

On PostgreSQL, MySQL and SQLite that stores an empty city, and `city IS NULL` is false for it. On
Oracle the empty string **is** null, so the row has no city at all, `city IS NULL` is true, and a
`NOT NULL` constraint on the column would have refused the insert.

Everything lesson 4 said about `NULL` then applies where you did not expect it: `WHERE city = ''`
matches nothing, ever, because it is `WHERE city = NULL`. Code ported to Oracle that distinguishes
"blank" from "not given" stops being able to.

**A `DATE` has a time in it.** Oracle's `DATE` is a date *and* a time to the second — it is closer
to the other engines' `timestamp` than to their `date`. So this is a bug on Oracle and not on the
others:

```sql
SELECT count(*) FROM orders WHERE ordered_on = DATE '2026-03-19';
```

It matches only the rows whose time component is exactly midnight. The fix is the one lesson 9
already argued for, a range rather than a function on the column:

```sql
SELECT count(*) FROM orders
 WHERE ordered_on >= DATE '2026-03-19' AND ordered_on < DATE '2026-03-20';
```

`TRUNC(ordered_on) = DATE '2026-03-19'` also works and defeats an ordinary index on the column,
for exactly the reason lesson 9 gave.

**There is one numeric type, and it is exact.** `NUMBER` is a variable-precision decimal, and
`NUMBER(10,2)` is what a money column should be, as lesson 3 asked. `INTEGER` is accepted and is a
`NUMBER(38)` underneath. `BINARY_FLOAT` and `BINARY_DOUBLE` exist for when you actually want
floating point, which for money you do not. This one is a pleasant surprise rather than a trap:
the default here is the careful one.

## The lookups

| | Oracle | PostgreSQL |
|---|---|---|
| a query with no table | `SELECT 1 FROM dual` | `SELECT 1` |
| first n rows | `FETCH FIRST n ROWS ONLY`, or `ROWNUM <= n` on older versions | `LIMIT n` |
| auto-numbered key | `GENERATED AS IDENTITY`, or a sequence and `seq.NEXTVAL` | `GENERATED ALWAYS AS IDENTITY` |
| concatenate | `\|\|` or `concat()` | the same |
| current time | `SYSDATE`, `SYSTIMESTAMP` | `now()`, `current_timestamp` |
| substring | `SUBSTR` | `substring` or `substr` |
| null replacement | `NVL(a, b)`, `COALESCE(a, b)` | `COALESCE(a, b)` |
| insert or update | `MERGE` | `ON CONFLICT … DO UPDATE`, and `MERGE` since 15 |
| describe a table | `DESC employees` in SQL\*Plus | `\d employees` in psql |
| the plan | `EXPLAIN PLAN FOR …` then `SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY)` | `EXPLAIN` |

**`DUAL` is the one that looks like a joke and is not.** Oracle's `SELECT` has always required a
`FROM`, so there is a one-row, one-column table in every database whose entire purpose is to be
selected from when you have nothing to select from. `SELECT SYSDATE FROM dual` is how you ask the
time. The 23ai line relaxes the requirement, and `DUAL` is in every system written before it,
which is every system you will meet.

**`ROWNUM` is the one that causes bugs.** It is assigned as rows are produced, *before* the sort,
so this does not return the three most recent orders:

```sql
SELECT * FROM orders WHERE ROWNUM <= 3 ORDER BY ordered_on DESC;
```

It takes the first three rows the query happened to produce and then sorts those three. The
correct older spelling wraps the sorted query and filters outside it, and on 12c and later
`FETCH FIRST 3 ROWS ONLY` does the right thing directly. Prefer it on any version that has it.

## The plan, which lesson 10 prepared you for

Oracle has all of lesson 10's machinery under different names. `EXPLAIN PLAN FOR` a statement
writes the plan into a table, and `DBMS_XPLAN.DISPLAY` formats it. For the plan of a statement
that actually ran, with the actual row counts beside the estimates, the call is
`DBMS_XPLAN.DISPLAY_CURSOR` with the `ALLSTATS LAST` format — and the statement has to have been
run with the `GATHER_PLAN_STATISTICS` hint.

Described rather than shown, the output is a table of plan lines. Each carries an id, a parent,
an operation such as `TABLE ACCESS FULL` or `INDEX RANGE SCAN`, the object it touches, and the
estimated rows and cost. Where the statistics were gathered, the estimated and actual row counts
sit in adjacent columns. The indentation is the tree, exactly as lesson 10 described it for
PostgreSQL.

**So the method transfers unchanged**, and the two habits from lesson 10 are the two habits here:
put the estimated and actual row counts side by side on every line, and treat the first line where
they diverge badly as where the query went wrong. Only the names moved: `TABLE ACCESS FULL` is a
sequential scan, `INDEX RANGE SCAN` is an index scan, `NESTED LOOPS`, `HASH JOIN` and
`SORT MERGE JOIN` are the three joins lesson 10 already named.
