---
title: When autovacuum decides to run
version: 1
---

Nobody types `VACUUM` after every change. The **autovacuum launcher**, one of the processes lesson 3
listed under the postmaster, wakes every minute, looks at each table's counters and starts a worker
for each table that has crossed its line. These are the settings that draw the line:

```
shop=# SELECT name, setting, unit FROM pg_settings WHERE name IN ('autovacuum', 'autovacuum_naptime', 'autovacuum_max_workers', 'autovacuum_vacuum_threshold', 'autovacuum_vacuum_scale_factor', 'autovacuum_vacuum_insert_threshold', 'autovacuum_vacuum_insert_scale_factor', 'autovacuum_vacuum_cost_limit', 'autovacuum_vacuum_cost_delay');
                 name                  | setting | unit 
---------------------------------------+---------+------
 autovacuum                            | on      | 
 autovacuum_max_workers                | 3       | 
 autovacuum_naptime                    | 60      | s
 autovacuum_vacuum_cost_delay          | 2       | ms
 autovacuum_vacuum_cost_limit          | -1      | 
 autovacuum_vacuum_insert_scale_factor | 0.2     | 
 autovacuum_vacuum_insert_threshold    | 1000    | 
 autovacuum_vacuum_scale_factor        | 0.2     | 
 autovacuum_vacuum_threshold           | 50      | 
(9 rows)
```

**A table is vacuumed once its dead versions pass a fixed number plus a share of the table**:

```sql
autovacuum_vacuum_threshold + autovacuum_vacuum_scale_factor * reltuples
```

`reltuples` is the planner's estimate of the rows in the table, kept in `pg_class`. With the
defaults, 50 and 0.2, a table is vacuumed once a fifth of it is dead. Three workers at most run at
once, and `autovacuum_vacuum_cost_limit` of -1 means each borrows the plain `VACUUM` budget of reads
and writes, then sleeps for `autovacuum_vacuum_cost_delay`, 2 ms. That throttle is what keeps
autovacuum from swallowing the disk.

There is a second trigger, for tables that only grow. **The insert threshold counts rows inserted
since the last vacuum**, 1,000 plus a fifth of the table, so a table nobody updates still gets its
visibility map set and its rows frozen. You have already seen it fire:

```
shop=# SELECT relname, last_analyze, last_autovacuum, autovacuum_count FROM pg_stat_user_tables WHERE relname IN ('customers', 'orders');
  relname  |         last_analyze          |        last_autovacuum        | autovacuum_count 
-----------+-------------------------------+-------------------------------+------------------
 customers | 2026-10-10 16:39:58.473499-03 | 2026-10-10 16:40:43.441353-03 |                1
 orders    | 2026-10-10 16:39:59.002546-03 | 2026-10-10 16:40:43.699616-03 |                1
(2 rows)
```

`last_analyze` is the `ANALYZE` at the end of `shop.sql`. Autovacuum visited both tables less than a
minute later, on the launcher's next round, although nothing had been updated or deleted: a million
inserted rows were well past 1,000 plus a fifth of a million.

## Working it out for orders

```
shop=# SELECT reltuples, 50 + 0.2 * reltuples AS vacuum_after, 50 + 0.1 * reltuples AS analyze_after FROM pg_class WHERE relname = 'orders';
 reltuples | vacuum_after | analyze_after 
-----------+--------------+---------------
     1e+06 |       200050 |        100050
(1 row)
```

**`orders` will be vacuumed after 200,050 dead versions**, and analysed after 100,050 changed rows,
which is the same formula with its own scale factor of 0.1 and the subject of lesson 16. The copy
has the same million rows, so the same numbers apply to it. Update 150,000 of them, which is past
the line for analysing and short of the line for vacuuming:

```
shop=# UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id <= 150000;
UPDATE 150000
```

Wait a minute for the launcher's next round, then look:

```
shop=# SELECT n_dead_tup, last_autovacuum, last_autoanalyze FROM pg_stat_user_tables WHERE relname = 'orders_copy';
 n_dead_tup | last_autovacuum |       last_autoanalyze        
------------+-----------------+-------------------------------
     150000 |                 | 2026-10-10 16:41:43.808939-03
(1 row)

shop=# UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id > 150000 AND id <= 250000;
UPDATE 100000
```

The worker came, analysed the table and left the 150,000 dead versions where they were. A second
`UPDATE` of 100,000 rows takes the count to 250,000. A minute later:

<<<the-trigger 7>>>

**`last_autovacuum` has a time, `autovacuum_count` is 1 and `n_dead_tup` is back to 0.** That is the whole mechanism, and on
a table of a million rows the defaults are reasonable.

On a table of a billion rows they are not. A fifth of a billion is 200 million dead versions before
the first vacuum, and when it comes it has 200 million versions to clear in one pass. **Large tables
want a smaller scale factor of their own**, set on the table rather than on the server, and the last
section of this lesson does that to the copy.
