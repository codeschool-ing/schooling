---
title: Change data capture for real, out of PostgreSQL's own log
version: 1
---

**DMS reads changes out of PostgreSQL through logical decoding**, and logical decoding is part of
PostgreSQL itself, so it can be run on your own computer and watched. That is what this section
does, with a real PostgreSQL 16 server and real changes. Nothing here imitates anything: what the
transcripts show is what DMS receives from a PostgreSQL source, before DMS turns it into rows on the
target.

**Three pieces make it work.** The **write-ahead log**, WAL, is where PostgreSQL writes every change
before applying it, and with `wal_level=logical` it writes enough to rebuild each changed row. A
**replication slot** is a named bookmark in that log, kept by the server for one reader: it
remembers how far the reader has confirmed, and it makes the server keep every piece of log the
reader has not read yet. An **output plugin** turns the log between the bookmark and now into
something a reader understands; `test_decoding`, which comes with PostgreSQL, turns it into lines of
text, and it is one of the two plugins DMS can use, the `PluginName` of the endpoint two sections ago.

## A throwaway server

If `sql-databases` lesson 1 installed PostgreSQL on your machine, it is all here; if not, the
section of that lesson on installing it is one command, `sudo apt install -y postgresql`. Its own
server runs on port 5432 with `wal_level=replica`, and this section leaves it alone: it starts a
second, throwaway server of your own on port 5433, in `~/aws/cdc`, listening on no network address
at all, only on a socket file in that directory. You need no `sudo` for it, because the server runs
as you.

```sh
PG=/usr/lib/postgresql/16/bin
mkdir -p ~/aws/cdc
$PG/initdb -D ~/aws/cdc/data -U postgres -A trust > ~/aws/cdc/initdb.log
$PG/pg_ctl -D ~/aws/cdc/data -l ~/aws/cdc/server.log -w start \
  -o "-c wal_level=logical -c port=5433 -c listen_addresses='' -c unix_socket_directories=$HOME/aws/cdc"
export PGHOST=$HOME/aws/cdc PGPORT=5433 PGUSER=postgres
```

`initdb` creates the data directory with a superuser called `postgres` that needs no password, which
is safe only because nothing but a socket in your own home directory can reach it. `pg_ctl` starts
the server with three settings given on its command line: logical WAL, the port, and no TCP at all.
The last line points `psql` at it for the rest of this terminal.

## A table, a slot, three changes

```
ana@laptop:~/aws$ psql -c "SHOW wal_level"
 wal_level 
-----------
 logical
(1 row)

ana@laptop:~/aws$ psql -c "CREATE TABLE orders (order_id text PRIMARY KEY, customer_id text NOT NULL, total_cents integer NOT NULL)" -c "INSERT INTO orders VALUES ('ord-1', 'c-17', 4590)"
CREATE TABLE
INSERT 0 1
ana@laptop:~/aws$ psql -c "SELECT slot_name, lsn FROM pg_create_logical_replication_slot('dms_orders', 'test_decoding')"
 slot_name  |    lsn    
------------+-----------
 dms_orders | 0/15183B0
(1 row)
```

**The slot was created at a position in the log**, the `lsn`, a log sequence number: the byte offset
in the WAL, written as two hexadecimal halves. The order inserted before the slot existed, `ord-1`,
will never be reported by it. That is the starting point a full-load-and-cdc task notes before it
copies a table, from the first section of this lesson. Now change the table three ways, and ask the
slot what it saw, first without consuming anything:

```
ana@laptop:~/aws$ psql -c "INSERT INTO orders VALUES ('ord-2', 'c-03', 12800)" -c "UPDATE orders SET total_cents = 4990 WHERE order_id = 'ord-1'" -c "DELETE FROM orders WHERE order_id = 'ord-2'"
INSERT 0 1
UPDATE 1
DELETE 1
ana@laptop:~/aws$ psql -Atc "SELECT lsn, xid, data FROM pg_logical_slot_peek_changes('dms_orders', NULL, NULL)"
0/15183B0|732|BEGIN 732
0/15183B0|732|table public.orders: INSERT: order_id[text]:'ord-2' customer_id[text]:'c-03' total_cents[integer]:12800
0/1518468|732|COMMIT 732
0/1518468|733|BEGIN 733
0/1518468|733|table public.orders: UPDATE: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990
0/15184F0|733|COMMIT 733
0/15184F0|734|BEGIN 734
0/15184F0|734|table public.orders: DELETE: order_id[text]:'ord-2'
0/1518568|734|COMMIT 734
```

**Every committed change, in commit order, each inside its transaction.** The insert carries the
whole new row with its types. The update carries the row as it is now. The delete carries only the
primary key, because by default that is all PostgreSQL writes to the log about a deleted row, and it
is enough to find the row on the target and delete it there. Each change sits between a `BEGIN` and
a `COMMIT` with its transaction id, `xid`, which is how a reader knows which changes stand or fall
together. A transaction that was rolled back is not there at all.

**`peek` read the changes and left them; `get` reads them and moves the bookmark.** Read the same
changes with `get`, and then again:

```
ana@laptop:~/aws$ psql -Atc "SELECT data FROM pg_logical_slot_get_changes('dms_orders', NULL, NULL)"
BEGIN 732
table public.orders: INSERT: order_id[text]:'ord-2' customer_id[text]:'c-03' total_cents[integer]:12800
COMMIT 732
BEGIN 733
table public.orders: UPDATE: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990
COMMIT 733
BEGIN 734
table public.orders: DELETE: order_id[text]:'ord-2'
COMMIT 734
ana@laptop:~/aws$ psql -Atc "SELECT count(*) FROM pg_logical_slot_get_changes('dms_orders', NULL, NULL)"
0
```

**The second read is empty, and that is the contract**: once a reader has taken changes, the server
forgets them, and it is free to recycle that part of the log. DMS reads through the same kind of slot,
and confirms only what it has applied on the target, but the bookmark moves the same way.

## What the old row was

**An update that carries only the new row cannot tell the target what changed**, and a target that
needs the old values, an audit table or a lake that keeps history, gets nothing. `REPLICA IDENTITY`
is the table's setting for how much of the old row goes into the log:

```
ana@laptop:~/aws$ psql -c "ALTER TABLE orders REPLICA IDENTITY FULL" -c "UPDATE orders SET total_cents = 5190 WHERE order_id = 'ord-1'"
ALTER TABLE
UPDATE 1
ana@laptop:~/aws$ psql -Atc "SELECT xid, data FROM pg_logical_slot_get_changes('dms_orders', NULL, NULL)"
735|BEGIN 735
735|COMMIT 735
736|BEGIN 736
736|table public.orders: UPDATE: old-key: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990 new-tuple: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:5190
736|COMMIT 736
```

**Now the update carries `old-key` and `new-tuple`**: 4990 before, 5190 after. The first, empty,
transaction is the `ALTER TABLE` itself, and it carries no change, because logical decoding does not
report changes to a table's structure. DMS deals with those separately, which is one more reason a
migration avoids changing a table's columns while it runs. `FULL` writes more WAL for every update
and delete of the table, which is the price, and a table with no primary key needs it, or something
like it, before its updates and deletes can be replicated at all.

## The slot that nobody reads

```
ana@laptop:~/aws$ psql -c "INSERT INTO orders SELECT 'bulk-' || g, 'c-' || (g % 50), 1000 FROM generate_series(1, 20000) g"
INSERT 0 20000
ana@laptop:~/aws$ psql -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
 slot_name  | active | retained 
------------+--------+----------
 dms_orders | f      | 3431 kB
(1 row)

ana@laptop:~/aws$ psql -Atc "SELECT pg_drop_replication_slot('dms_orders')" -c "SELECT count(*) FROM pg_replication_slots"

0
```

**Twenty thousand rows inserted and nobody reading: the slot is holding 3431 kB of log** that the
server would otherwise have recycled. That is the danger of CDC on PostgreSQL that matters, and it is not
in DMS at all. A slot keeps the WAL its reader has not confirmed, without limit by default, so a task
that is stopped for a weekend, or deleted while its slot is left behind, makes the old database
keep every change it makes until its disk fills, and a full disk stops the shop. **The rule is to
drop the slot when the reader is gone**, which the last command did, and to watch the retained size
of every slot while one exists. Since version 13 PostgreSQL can also cap it with
`max_slot_wal_keep_size`, which gives up on a slot that falls too far behind rather than filling the
disk; the reader then has to start again from a new full load.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two rows of ten WAL segments, oldest on the left. When the reader keeps up, the six oldest segments are recycled by the server and only those from the slot's restart_lsn to now are kept until the reader confirms them. When the reader has stopped, restart_lsn stays near the start and every segment since then is kept, until the disk fills.\" data-fig=\"l26-slot\"><defs><marker id=\"ah-l26-slot\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">reader keeps up</text><rect x=\"120\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"176\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"232\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"288\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"344\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"400\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"456\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"568\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"624\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"453\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">restart_lsn</text><text x=\"674\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">now</text><text x=\"285\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recycled by the server</text><text x=\"593.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">kept until confirmed</text><text x=\"20\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">reader stopped</text><rect x=\"120\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"176\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"232\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"288\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"344\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"400\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"456\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"568\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"624\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"229\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">restart_lsn</text><text x=\"453\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">every segment since then is kept, until the disk fills</text><text x=\"397\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">WAL segments, oldest on the left</text></svg>", "caption": "A slot makes the server keep every piece of log its reader has not confirmed, with no limit unless one is set."}
```

When you are done, stop the throwaway server and delete it; nothing else on your machine used it:

```sh
$PG/pg_ctl -D ~/aws/cdc/data stop
rm -rf ~/aws/cdc
```
