---
title: When autovacuum analyses a table by itself
version: 1
---

Nobody on a working server types `ANALYZE` after every change. **Autovacuum analyses tables as
well as vacuuming them**, and lesson 14 met the half that vacuums. The half that analyses has its
own trigger, built the same way: a fixed number of rows plus a share of the table.

```
shop=# SELECT name, setting FROM pg_settings WHERE name IN ('autovacuum_analyze_threshold', 'autovacuum_analyze_scale_factor', 'autovacuum_naptime');
              name               | setting 
---------------------------------+---------
 autovacuum_analyze_scale_factor | 0.1
 autovacuum_analyze_threshold    | 50
 autovacuum_naptime              | 60
(3 rows)

shop=# SELECT reltuples, 50 + 0.1 * reltuples AS analyze_after FROM pg_class WHERE relname = 'orders_copy';
 reltuples | analyze_after 
-----------+---------------
   1.3e+06 |        130050
(1 row)
```

**A table is analysed once `n_mod_since_analyze` passes 50 plus a tenth of its rows.** For the
copy, which holds 1.3 million rows since the import, that is 130,050 changed rows. An insert, an
update and a delete each count as one. The launcher does not watch continuously: it visits each
database about once every `autovacuum_naptime`, 60 seconds, and starts a worker for the tables that
have crossed the line.

## Watching it happen

The import has been processed, and every `pending` order becomes `paid`. That is 300,000 updated
rows, well past the line. Then autovacuum is allowed back on the copy:

```
shop=# UPDATE orders_copy SET status = 'paid' WHERE status = 'pending';
UPDATE 300000

shop=# ALTER TABLE orders_copy RESET (autovacuum_enabled);
ALTER TABLE

shop=# SELECT now()::time(0), n_mod_since_analyze, last_analyze::time(0), last_autoanalyze::time(0) FROM pg_stat_user_tables WHERE relname = 'orders_copy';
   now    | n_mod_since_analyze | last_analyze | last_autoanalyze 
----------+---------------------+--------------+------------------
 04:27:00 |              300000 | 04:26:53     | 
(1 row)
```

`RESET` puts the table back on the server's defaults; there is no setting left on it. Wait a
minute and ask again:

```
shop=# SELECT now()::time(0), n_mod_since_analyze, last_analyze::time(0), last_autoanalyze::time(0) FROM pg_stat_user_tables WHERE relname = 'orders_copy';
   now    | n_mod_since_analyze | last_analyze | last_autoanalyze 
----------+---------------------+--------------+------------------
 04:27:42 |                   0 | 04:26:53     | 04:27:41
(1 row)

shop=# DROP TABLE orders_copy;
DROP TABLE
```

`last_autoanalyze` filled in 41 seconds after the first query, and `n_mod_since_analyze` went back
to zero. The two columns tell apart who did it: `last_analyze` is an `ANALYZE` somebody typed,
`last_autoanalyze` is the launcher's. The copy has done its job and is dropped.

On the recording machine the wait was 41 seconds. On yours it will be anything up to a minute, and
longer on a busy server, where every worker is already busy with a big table. **That wait is the
window from the previous section, and on a working server nobody holds it open on purpose: it is
simply there**, after every large change, for as long as autovacuum takes to arrive.

## Where the trigger is too blunt

A tenth of the table is a sensible line for a table of a million rows. On a table of a hundred
million it is ten million changed rows, and an import of five million never reaches it. Those five
million can be exactly the `pending` orders of the last section, a new value the summary has never
seen. **A large table that receives batches gets a lower scale factor of its own**, set on the
table the way lesson 14 set its vacuum thresholds:

```sql
ALTER TABLE orders SET (autovacuum_analyze_scale_factor = 0.02);
```

That is not run here, because `orders` does not need it at a million rows. The other fix is the one from the previous section, which
does not depend on any threshold: the job that made the change runs the `ANALYZE`.

Two kinds of table autovacuum never analyses at all. **A temporary table** is visible only to the
session that created it, so no worker can read it, and a session that loads one and then joins
against it has to analyse it itself. **A partitioned table's parent** is not analysed either, only
its partitions, so the statistics for the table as a whole come from an `ANALYZE` you run;
`db-performance` lessons 17 and 18 are about partitioning.

The counters behind all of this live in memory and are written to disk at a clean shutdown. After a
crash, such as the one lesson 8 causes on purpose, they start from zero: every table's
`n_mod_since_analyze` forgets what came before, and the next automatic analysis arrives later than
it would have. The summary itself, in `pg_statistic`, is an ordinary table and survives.
