---
title: Wraparound, the counter that cannot run out
version: 1
---

Every transaction that changes something gets a number, and `xmin` and `xmax` are those numbers.
**They are 32 bits wide**, about four billion values, and a busy server uses up a billion in a
year or two. So the numbers are compared on a circle: from any transaction, two billion are in the
past and two billion are in the future. A row written by transaction 782 is in the past for
transaction 805. Two billion transactions later, the same 782 would land in the future, and
**the row would vanish** from every query without anybody having deleted it.

Freezing is what prevents that. A frozen row is visible to everybody whatever its number says, so
its `xmin` no longer takes part in the comparison. Each table records the oldest unfrozen
transaction it might still contain in `relfrozenxid`, each database records the oldest of its
tables in `datfrozenxid`, and `age()` turns either into a count of transactions:

```
shop=# SELECT datname, age(datfrozenxid) FROM pg_database;
  datname  | age 
-----------+-----
 postgres  |  84
 ana       |  84
 template1 |  84
 template0 |  84
 shop      |  84
(5 rows)

shop=# SELECT relname, age(relfrozenxid) FROM pg_class WHERE relkind = 'r' ORDER BY 2 DESC LIMIT 3;
     relname      | age 
------------------+-----
 pg_foreign_table |  84
 pg_type          |  84
 pg_authid        |  84
(3 rows)

shop=# SHOW autovacuum_freeze_max_age;
 autovacuum_freeze_max_age 
---------------------------
 200000000
(1 row)
```

`shop`'s server is young, so every age is a few dozen. **`autovacuum_freeze_max_age` is the
line**: a table whose age passes 200 million gets an aggressive autovacuum that reads every page
not already frozen, whatever its dead rows look like. It runs even with `autovacuum` turned off, and
it does not step aside when somebody else wants a lock on the table, as an ordinary autovacuum
does. On a large table that nobody has thought about, that aggressive pass is often the first time
anybody notices autovacuum at all, because it reads the whole table at a time nobody chose.

## What it looks like when that does not work

Waiting two billion transactions to see the end is not practical. `pg_resetwal` can set the next
transaction id of a stopped cluster directly, and that is enough to see it on a **scratch cluster
made for the purpose**, never on one you care about. `pg_resetwal` throws away the write-ahead log,
which on a real cluster loses data. The `dd` creates the piece of the commit log, in `pg_xact`, that
the new transaction id needs; without it the server could not record whether that transaction
committed:

```
ana@db:~$ sudo pg_createcluster 16 wrap >/dev/null
ana@db:~$ sudo -u postgres /usr/lib/postgresql/16/bin/pg_resetwal -x 2145000000 /var/lib/postgresql/16/wrap
Write-ahead log reset
ana@db:~$ sudo -u postgres dd if=/dev/zero of=/var/lib/postgresql/16/wrap/pg_xact/07FD bs=256k count=1 status=none
ana@db:~$ sudo pg_ctlcluster 16 wrap start
ana@db:~$ sudo -u postgres psql -p 5433 -c "SELECT datname, age(datfrozenxid) FROM pg_database;"
  datname  |    age     
-----------+------------
 postgres  | 2144999278
 template1 | 2144999278
 template0 | 2144999278
(3 rows)

ana@db:~$ sudo -u postgres psql -p 5433 -c "CREATE TABLE t (i int);"
ERROR:  database is not accepting commands to avoid wraparound data loss in database "template1"
HINT:  Stop the postmaster and vacuum that database in single-user mode.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
ana@db:~$ sudo -u postgres psql -p 5433 -c "SELECT count(*) FROM pg_class;"
 count 
-------
   413
(1 row)
```

The ages are 2,144,999,278, just short of 2,147,483,648, where the circle would turn.
**The server refuses anything that needs a new transaction id** and goes on serving reads: the
`CREATE TABLE` fails, the `count(*)` works. It does that 3 million transactions before the point
of no return, and from 40 million before it every new transaction id comes with a warning in the
log. Those warnings are the alarm that a monitored server would have raised weeks earlier; this
cluster jumped past them.

The way out is a VACUUM that freezes every database:

```
ana@db:~$ sudo -u postgres vacuumdb -p 5433 --all --freeze 2> vacuum.log
vacuumdb: vacuuming database "postgres"
vacuumdb: vacuuming database "template1"
ana@db:~$ grep -c "as a failsafe" vacuum.log
216
ana@db:~$ grep -m1 -A3 "as a failsafe" vacuum.log
WARNING:  bypassing nonessential maintenance of table "postgres.pg_catalog.pg_proc" as a failsafe after 0 index scans
DETAIL:  The table's relfrozenxid or relminmxid is too far in the past.
HINT:  Consider increasing configuration parameter "maintenance_work_mem" or "autovacuum_work_mem".
You might also need to consider other ways for VACUUM to keep up with the allocation of transaction IDs.
ana@db:~$ grep -A2 "must be vacuumed" vacuum.log
WARNING:  database "template1" must be vacuumed within 2484369 transactions
HINT:  To avoid a database shutdown, execute a database-wide VACUUM in that database.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
--
WARNING:  database "template0" must be vacuumed within 2484369 transactions
HINT:  To avoid a database shutdown, execute a database-wide VACUUM in that database.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
```

**`as a failsafe`** appeared 216 times. Past `vacuum_failsafe_age`, 1.6 billion by default, VACUUM
drops everything except freezing: no index cleanup, no throttling, only getting the age back down.
The warnings at the end name the databases still at risk.

```
ana@db:~$ sudo -u postgres psql -p 5433 -c "SELECT datname, datallowconn, age(datfrozenxid) FROM pg_database;"
  datname  | datallowconn |    age     
-----------+--------------+------------
 postgres  | t            |          0
 template1 | t            |          0
 template0 | f            | 2144999278
(3 rows)
```

`postgres` and `template1` are at 0. **`template0` is not**, because it does not accept connections
and `vacuumdb --all` skips it, so the server still refuses. That one belongs to autovacuum, which
can reach it, and within about a minute it had:

```
ana@db:~$ sudo -u postgres psql -p 5433 -c "SELECT datname, datallowconn, age(datfrozenxid) FROM pg_database;"
  datname  | datallowconn | age 
-----------+--------------+-----
 postgres  | t            |   0
 template1 | t            |   0
 template0 | f            |   0
(3 rows)

ana@db:~$ sudo -u postgres psql -p 5433 -c "CREATE TABLE t (i int);"
CREATE TABLE
ana@db:~$ sudo pg_dropcluster --stop 16 wrap
```

The hint in the refusal says to stop the server and vacuum in single-user mode. Here an ordinary
`vacuumdb`, with the server up and still serving reads, did the work, and autovacuum did the rest.
Stopping the server takes it away from everybody, so try the ordinary way first.

On this cluster the whole emergency took a minute, because it holds almost nothing. On a server with
a two-terabyte table, the same freeze reads two terabytes while the application cannot write, and
it can take most of a day. **The cure is to never get there**: watch `age(datfrozenxid)` the way the
first query above does, and treat an age that keeps climbing past `autovacuum_freeze_max_age` as an
incident. It means autovacuum cannot finish, usually for a reason the previous section already
named.
