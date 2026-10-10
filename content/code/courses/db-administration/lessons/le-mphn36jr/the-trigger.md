---
title: When autovacuum decides to run
version: 1
---

Nobody types `VACUUM` after every change. The **autovacuum launcher**, one of the processes lesson 3
listed under the postmaster, wakes every minute, looks at each table's counters and starts a worker
for each table that has crossed its line. These are the settings that draw the line:

<<<the-trigger 1>>>

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

<<<the-trigger 2>>>

`last_analyze` is the `ANALYZE` at the end of `shop.sql`. Autovacuum visited both tables a minute
later, on the launcher's next round, although nothing had been updated or deleted: a million
inserted rows were well past 1,000 plus a fifth of a million.

## Working it out for orders

<<<the-trigger 3>>>

**`orders` will be vacuumed after 200,050 dead versions**, and analysed after 100,050 changed rows,
which is the same formula with its own scale factor of 0.1 and the subject of lesson 16. The copy
has the same million rows, so the same numbers apply to it. Update 150,000 of them, which is past
the line for analysing and short of the line for vacuuming:

<<<the-trigger 4>>>

Wait a minute for the launcher's next round, then look:

<<<the-trigger 5-6>>>

The worker came, analysed the table and left the 150,000 dead versions where they were. A second
`UPDATE` of 100,000 rows takes the count to 250,000. A minute later:

<<<the-trigger 7>>>

**`last_autovacuum` has a time and `n_dead_tup` is back to 0.** That is the whole mechanism, and on
a table of a million rows the defaults are reasonable.

On a table of a billion rows they are not. A fifth of a billion is 200 million dead versions before
the first vacuum, and when it comes it has 200 million versions to clear in one pass. **Large tables
want a smaller scale factor of their own**, set on the table rather than on the server, and the last
section of this lesson does that to the copy.
