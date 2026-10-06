---
title: What a column store is bad at
version: 1
---

Every advantage in this lesson came from keeping each column together, compressed, in large blocks. The
same choice makes a column store bad at the till's job.

**Writing one row at a time.** A row has to be split into its columns and appended to eleven compressed
blocks. Two thousand inserts, each its own statement and its own transaction, into PostgreSQL and into a
DuckDB file:

```
ana@lab:~/wh$ seq 1 2000 | awk '{ print "INSERT INTO t VALUES (" $1 ", " $1 * 7 ");" }' > inserts.sql
ana@lab:~/wh$ head -2 inserts.sql
INSERT INTO t VALUES (1, 7);
INSERT INTO t VALUES (2, 14);
ana@lab:~/wh$ psql -q -c 'CREATE TABLE t (a int, b int)'
ana@lab:~/wh$ TIMEFORMAT='%R seconds'; time psql -q -f inserts.sql
0.956 seconds
ana@lab:~/wh$ duckdb small.duckdb -c 'CREATE TABLE t (a int, b int)'
ana@lab:~/wh$ TIMEFORMAT='%R seconds'; time duckdb small.duckdb < inserts.sql
1.981 seconds
```

**0.956 seconds for PostgreSQL, 1.981 for DuckDB**, one run each, and both including the time to start the
program. The row store appends a row to a page. The column store has to record each single-row change
durably, eleven columns at a time, two thousand times. Written as one batch, the same rows are one append per column instead
of two thousand, which is why every load in this course writes whole tables, never single rows.

**Updating and deleting rows.** A value in a compressed, encoded block cannot be changed in place without
rewriting the block. Column stores handle it by marking rows as deleted and writing new versions elsewhere,
and cleaning up later. That works, and it is slow for many small changes.

**Fetching one row by its key.** The row's eleven values are in eleven places. With the data sorted by that
key, zone maps find it quickly:

```
ana@lab:~/wh$ psql -f lookup.sql
Timing is on.
CREATE INDEX
Time: 271.006 ms
 line_no | net_cents 
---------+-----------
       1 |      3290
       2 |      2990
       3 |      6890
(3 rows)

Time: 0.852 ms
ana@lab:~/wh$ duckdb wh.duckdb < duck-lookup.sql
┌─────────┬───────────┐
│ line_no │ net_cents │
│  int64  │   int64   │
├─────────┼───────────┤
│       1 │      3290 │
│       2 │      2990 │
│       3 │      6890 │
└─────────┴───────────┘
Run Time (s): real 0.002 user 0.001994 sys 0.000664
```

PostgreSQL, with the index it had to build first, answered in 0.852 milliseconds; DuckDB, with no index, in
0.002 seconds. Both are fast at this size, and DuckDB's is fast only because `fact_sales` is sorted by order
number; a lookup by a column the table is not sorted on would have to scan it.

**This is why lesson 1 kept two databases.** The operational database stores rows because the till writes
rows. The warehouse stores columns because the report reads columns. HTAP products, from lesson 1, keep both
copies inside one product for exactly this reason. Lesson 9 is the column stores you rent rather than run.
