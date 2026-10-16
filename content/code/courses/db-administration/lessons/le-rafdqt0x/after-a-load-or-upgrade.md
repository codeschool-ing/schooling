---
title: After a restore or an upgrade, there is no summary at all
version: 1
---

The stale summary of the earlier sections at least described the table as it used to be. **A
database restored from a dump has no summary whatsoever**, because `pg_dump` copies the schema and
the rows and not `pg_statistic`. The tables are full and the planner knows nothing about what is in
them.

A dump and a restore into a second database, to see it. Backups are `db-reliability`'s subject from
lesson 1 on; the first three commands here only make a copy:

```
ana@db:~$ pg_dump -Fc -f shop.dump shop
ana@db:~$ createdb shop_restore
ana@db:~$ pg_restore -d shop_restore shop.dump
ana@db:~$ psql shop_restore -c "SELECT count(*) FROM pg_stats WHERE schemaname = 'public';"
 count 
-------
     0
(1 row)

ana@db:~$ psql shop_restore -c "EXPLAIN SELECT * FROM orders WHERE status = 'cancelled';"
                                 QUERY PLAN                                  
-----------------------------------------------------------------------------
 Gather  (cost=1000.00..15100.33 rows=5000 width=60)
   Workers Planned: 2
   ->  Parallel Seq Scan on orders  (cost=0.00..13600.33 rows=2083 width=60)
         Filter: (status = 'cancelled'::text)
(4 rows)
```

No rows in `pg_stats` for any column of any table. `rows=5000` is not an estimate of anything: with
no statistics, the planner assumes that an equality matches half a percent of the table, whatever
the table and whatever the value. It is wrong by a factor of forty here, and on another query it
would be wrong in the other direction.

Autovacuum would get to these tables eventually, since every restored row counts as a change. On a
database of a hundred tables it gets to them one at a time, while the application is already
sending queries planned on half a percent.

## In stages, so the first plans are usable sooner

```
ana@db:~$ vacuumdb --analyze-in-stages -d shop_restore
vacuumdb: processing database "shop_restore": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "shop_restore": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "shop_restore": Generating default (full) optimizer statistics
ana@db:~$ psql shop_restore -c "EXPLAIN SELECT * FROM orders WHERE status = 'cancelled';"
                           QUERY PLAN                           
----------------------------------------------------------------
 Seq Scan on orders  (cost=0.00..20892.00 rows=194033 width=34)
   Filter: (status = 'cancelled'::text)
(2 rows)
```

`vacuumdb` runs `VACUUM` or `ANALYZE` over a whole database from the shell, and
`--analyze-in-stages` runs only `ANALYZE`, three times. **The first pass uses a statistics target of
1**, a sample of 300 rows per table, and finishes almost at once: the estimates are rough, but they
are estimates, and the plans stop being guesses. The second uses 10, and the third the normal target,
after which the same `EXPLAIN` expects 194,033 cancelled orders where there are 200,000.
On a large database the first pass is the one that lets the application back on, and the full
summary arrives behind it.

It does more work in total than a single `ANALYZE`, since every table is analysed three times. When
nothing is waiting to use the database, `vacuumdb --analyze-only` does one pass, and `-j 4` spreads
it over four connections.

The restored copy is not needed any more:

```
ana@db:~$ dropdb shop_restore
ana@db:~$ rm shop.dump
```

## The moments that need it

**After a major upgrade with `pg_upgrade`**, which carries the data files across and, up to
PostgreSQL 17, leaves the statistics behind. `pg_upgrade` prints the `vacuumdb` command at the end
of its run, and it is the first thing to do once the new server is up. PostgreSQL 18 carries most of
them over; lesson 20 upgrades 16 to 17, where it is still your job.

**After a restore**, as above, and after loading a database with a migration tool such as the one
lesson 21 uses.

**After building an index on an expression**, such as `lower(email)`. The planner keeps statistics
for the expression as if it were a column, and they are collected by the next `ANALYZE` of the
table, not by `CREATE INDEX`.

**After any bulk change to one table**, which is the previous sections' case: an `ANALYZE` of that
table, by the job that made the change.

A minor upgrade, 16.2 to 16.15 as in lesson 20, touches none of this. It replaces the programs and
keeps the data directory, `pg_statistic` included.
