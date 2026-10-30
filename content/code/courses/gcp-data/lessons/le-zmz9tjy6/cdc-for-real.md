---
title: Change data capture for real, out of PostgreSQL's own log
version: 1
---

**Datastream reads changes out of PostgreSQL through logical decoding**, and logical decoding is part
of PostgreSQL itself, so it can be run on your own computer and watched. This section does that with
a real PostgreSQL 16 server and real changes. Nothing here imitates Datastream: what the transcripts
show is what any reader of a PostgreSQL source receives, Datastream included, before it turns the
changes into rows in BigQuery or files in a bucket.

**Four pieces make it work.** The **write-ahead log**, WAL, is where PostgreSQL writes every change
before applying it, and with `wal_level=logical` it writes enough to rebuild each changed row. A
**publication** names the tables whose changes may be published, which is how a source says "these
and no others". A **replication slot** is a named bookmark in the log, kept by the server for one
reader: it remembers how far the reader has confirmed, and it makes the server keep every piece of
log the reader has not read yet. An **output plugin** turns the log between the bookmark and now
into something a reader understands. Datastream's source configuration names a slot and a
publication, the two fields the previous section's help printed, and the slot it reads uses
`pgoutput`, the plugin PostgreSQL's own replication speaks.

## A throwaway server

If `sql-databases` installed PostgreSQL on your machine, it is all here; if not, Ubuntu's package is
one command:

```sh
sudo apt-get install -y postgresql-16
```

Its own server runs on port 5432, and this section leaves it alone: it starts a second, throwaway
server of your own on port 5433, in `~/gcp/cdc`, listening on no network address at all, only on a
socket file in that directory. You need no `sudo` for it, because the server runs as you:

```sh
PG=/usr/lib/postgresql/16/bin
mkdir -p ~/gcp/cdc
$PG/initdb -D ~/gcp/cdc/data -U postgres -A trust > ~/gcp/cdc/initdb.log
$PG/pg_ctl -D ~/gcp/cdc/data -l ~/gcp/cdc/server.log -w start \
  -o "-c wal_level=logical -c port=5433 -c listen_addresses='' -c unix_socket_directories=$HOME/gcp/cdc"
export PGHOST=$HOME/gcp/cdc PGPORT=5433 PGUSER=postgres
```

`initdb` creates the data directory with a superuser called `postgres` that needs no password, which
is safe only because nothing but a socket in your own home directory can reach it. `pg_ctl` starts
the server with four settings on its command line: logical WAL, the port, no TCP at all, and where
the socket goes. The last line points `psql` at it for the rest of this terminal.

## A table, a publication, two slots

```
ana@laptop:~/gcp$ psql -c "SHOW wal_level"
 wal_level 
-----------
 logical
(1 row)

ana@laptop:~/gcp$ psql -c "CREATE TABLE orders (order_id text PRIMARY KEY, customer_id text NOT NULL, total_cents integer NOT NULL)" -c "INSERT INTO orders VALUES ('ord-1', 'c-17', 4590)"
CREATE TABLE
INSERT 0 1
ana@laptop:~/gcp$ psql -c "CREATE PUBLICATION datastream_pub FOR TABLE orders"
CREATE PUBLICATION
ana@laptop:~/gcp$ psql -c "SELECT slot_name, lsn FROM pg_create_logical_replication_slot('datastream_orders', 'pgoutput')" -c "SELECT slot_name, lsn FROM pg_create_logical_replication_slot('look', 'test_decoding')"
     slot_name     |    lsn    
-------------------+-----------
 datastream_orders | 0/151AB00
(1 row)

 slot_name |    lsn    
-----------+-----------
 look      | 0/151AB38
(1 row)
```

**Two slots on the same log, for two readers.** `datastream_orders` uses `pgoutput`, as Datastream's
does. `look` uses `test_decoding`, a plugin that ships with PostgreSQL and turns changes into lines
of text, which is the one to read by eye. **Each slot was created at a position in the log**, the
`lsn`, a log sequence number: the byte offset in the WAL, written as two hexadecimal halves. The
order inserted before the slots existed, `ord-1`, will never be reported by either. That position is
the starting point a stream notes before its backfill, from the first section of this lesson. Now
change the table three ways, and ask the text slot what it saw, without consuming anything:

```
ana@laptop:~/gcp$ psql -c "INSERT INTO orders VALUES ('ord-2', 'c-03', 12800)" -c "UPDATE orders SET total_cents = 4990 WHERE order_id = 'ord-1'" -c "DELETE FROM orders WHERE order_id = 'ord-2'"
INSERT 0 1
UPDATE 1
DELETE 1
ana@laptop:~/gcp$ psql -Atc "SELECT lsn, xid, data FROM pg_logical_slot_peek_changes('look', NULL, NULL)"
0/151AB38|733|BEGIN 733
0/151AB38|733|table public.orders: INSERT: order_id[text]:'ord-2' customer_id[text]:'c-03' total_cents[integer]:12800
0/151ABF0|733|COMMIT 733
0/151ABF0|734|BEGIN 734
0/151ABF0|734|table public.orders: UPDATE: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990
0/151AC78|734|COMMIT 734
0/151AC78|735|BEGIN 735
0/151AC78|735|table public.orders: DELETE: order_id[text]:'ord-2'
0/151ACF0|735|COMMIT 735
```

**Every committed change, in commit order, each inside its transaction.** The insert carries the
whole new row with its types. The update carries the row as it is now. The delete carries only the
primary key, because by default that is all PostgreSQL writes to the log about a deleted row, and it
is enough to find the row on the destination and delete it there. Each change sits between a
`BEGIN` and a `COMMIT` with its transaction id, `xid`, which is how a reader knows which changes
stand or fall together. A transaction that was rolled back is not there at all.

## What Datastream's slot holds

**The `pgoutput` slot saw the same three transactions, as binary messages.** Its changes are read
with the binary form of the same function, given the protocol version and the publication, and the
first byte of each message says what it is:

```
ana@laptop:~/gcp$ psql -c "SELECT lsn, xid, chr(get_byte(data, 0)) AS kind, length(data) AS bytes FROM pg_logical_slot_peek_binary_changes('datastream_orders', NULL, NULL, 'proto_version', '1', 'publication_names', 'datastream_pub')"
    lsn    | xid | kind | bytes 
-----------+-----+------+-------
 0/151AB38 | 733 | B    |    21
 0/151AB38 | 733 | R    |    82
 0/151AB38 | 733 | I    |    37
 0/151ABF0 | 733 | C    |    26
 0/151ABF0 | 734 | B    |    21
 0/151ABF0 | 734 | U    |    36
 0/151AC78 | 734 | C    |    26
 0/151AC78 | 735 | B    |    21
 0/151AC78 | 735 | D    |    20
 0/151ACF0 | 735 | C    |    26
(10 rows)
```

**`B` begins a transaction, `C` commits it, and `I`, `U` and `D` are the insert, the update and the
delete**, at the same positions and with the same transaction ids as the text slot printed. `R`, a
relation message, describes the table's columns once before its first change, so that a reader can
decode the rows that follow without asking the database. This is the stream of bytes Datastream
reads, and it is why the source configuration needs a publication: `pgoutput` publishes only the
tables the publication names.

## Reading moves the bookmark

**`peek` read the changes and left them; `get` reads them and moves the bookmark.** Read the text
slot with `get`, and then again:

```
ana@laptop:~/gcp$ psql -Atc "SELECT data FROM pg_logical_slot_get_changes('look', NULL, NULL)"
BEGIN 733
table public.orders: INSERT: order_id[text]:'ord-2' customer_id[text]:'c-03' total_cents[integer]:12800
COMMIT 733
BEGIN 734
table public.orders: UPDATE: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990
COMMIT 734
BEGIN 735
table public.orders: DELETE: order_id[text]:'ord-2'
COMMIT 735
ana@laptop:~/gcp$ psql -Atc "SELECT count(*) FROM pg_logical_slot_get_changes('look', NULL, NULL)"
0
```

**The second read is empty, and that is the contract**: once a reader has taken its changes, the
server forgets them for that slot and may recycle that part of the log. Datastream reads through
its slot over a replication connection and confirms what it has written to the destination, but
the bookmark moves the same way. The `pgoutput` slot, which nobody has read, still holds all three
transactions.

## What the old row was

**An update that carries only the new row cannot tell the destination what changed**, and a
destination that keeps history gets nothing about the old values. `REPLICA IDENTITY` is the table's
setting for how much of the old row goes into the log:

```
ana@laptop:~/gcp$ psql -c "ALTER TABLE orders REPLICA IDENTITY FULL" -c "UPDATE orders SET total_cents = 5190 WHERE order_id = 'ord-1'"
ALTER TABLE
UPDATE 1
ana@laptop:~/gcp$ psql -Atc "SELECT xid, data FROM pg_logical_slot_get_changes('look', NULL, NULL)"
736|BEGIN 736
736|COMMIT 736
737|BEGIN 737
737|table public.orders: UPDATE: old-key: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990 new-tuple: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:5190
737|COMMIT 737
```

**Now the update carries `old-key` and `new-tuple`**: 4990 before, 5190 after. The first, empty,
transaction is the `ALTER TABLE` itself, and it carries no change, because logical decoding does not
report changes to a table's structure; Datastream finds a table's new columns its own way, which is
one more reason a migration avoids changing a table's columns while it runs. `FULL` writes more WAL
for every update and delete of the table, which is the price, and a table with no primary key needs
it, or something like it, before its updates and deletes can be replicated at all.

## The slot that nobody reads

```
ana@laptop:~/gcp$ psql -c "INSERT INTO orders SELECT 'bulk-' || g, 'c-' || (g % 50), 1000 FROM generate_series(1, 20000) g"
INSERT 0 20000
ana@laptop:~/gcp$ psql -c "SELECT slot_name, plugin, active, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
     slot_name     |    plugin     | active | wal_status | retained 
-------------------+---------------+--------+------------+----------
 datastream_orders | pgoutput      | f      | reserved   | 3431 kB
 look              | test_decoding | f      | reserved   | 3431 kB
(2 rows)

ana@laptop:~/gcp$ psql -Atc "SELECT pg_drop_replication_slot('look')"
```

**Twenty thousand rows inserted and nobody reading: each slot is holding the log since its own
bookmark.** That is the danger of CDC on PostgreSQL that matters, and it is not in Datastream at
all. A slot keeps the WAL its reader has not confirmed, without limit by default. So a stream that is paused for a weekend, or deleted while its slot is left behind, makes the shop's database keep
every change it makes until its disk fills, and a full disk stops the shop. **The rule is to drop a
slot when its reader is gone**, which the last command did for `look`, and to watch the retained
size of every slot while one exists.

**PostgreSQL can also put a ceiling on it.** `max_slot_wal_keep_size` is the most WAL any slot may
hold, and a slot that falls further behind than that is given up rather than allowed to fill the
disk. Set it low, write more than it allows, and watch:

```
ana@laptop:~/gcp$ psql -c "ALTER SYSTEM SET max_slot_wal_keep_size = '32MB'" -c "SELECT pg_reload_conf()"
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@laptop:~/gcp$ psql -c "INSERT INTO orders SELECT 'more-' || g, 'c-' || (g % 50), 1000 FROM generate_series(1, 400000) g"
INSERT 0 400000
ana@laptop:~/gcp$ psql -c "SELECT slot_name, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained, pg_size_pretty(safe_wal_size) AS safe FROM pg_replication_slots"
     slot_name     | wal_status | retained |  safe  
-------------------+------------+----------+--------
 datastream_orders | unreserved | 71 MB    | -28 MB
(1 row)

ana@laptop:~/gcp$ psql -c "CHECKPOINT" -c "SELECT slot_name, wal_status FROM pg_replication_slots"
CHECKPOINT
     slot_name     | wal_status 
-------------------+------------
 datastream_orders | lost
(1 row)

ana@laptop:~/gcp$ psql -c "SELECT count(*) FROM pg_logical_slot_peek_binary_changes('datastream_orders', NULL, NULL, 'proto_version', '1', 'publication_names', 'datastream_pub')"
ERROR:  can no longer get changes from replication slot "datastream_orders"
DETAIL:  This slot has been invalidated because it exceeded the maximum reserved size.
ana@laptop:~/gcp$ psql -Atc "SELECT pg_drop_replication_slot('datastream_orders')" -c "SELECT count(*) FROM pg_replication_slots"

0
```

**`unreserved`, then `lost`.** With 71 MB to hold and 32 MB allowed, the slot's status turned
`unreserved` and its safe size went negative: the server was telling anyone watching that the next
checkpoint would remove log the slot still needed. The checkpoint did, the slot became `lost`, and
reading it is now an error. **The disk was saved and the stream was not**: a Datastream stream on a
slot like this one cannot continue, and the way back is a new slot and a new backfill. That is the
trade the setting makes, and on a database that must not stop it is the right one, with an alert on
`wal_status` long before it happens.

When you are done, stop the throwaway server and delete it; nothing else on your machine used it:

```sh
$PG/pg_ctl -D ~/gcp/cdc/data stop
rm -rf ~/gcp/cdc
```
