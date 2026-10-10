---
title: The lock queue
version: 1
---

The usual fear about changing a live table is the wrong one. People worry that the `ALTER TABLE`
itself will take long. **Many `ALTER TABLE` commands finish in milliseconds, and still take a site
down**, because of what happens while they wait to start.

Almost every form of `ALTER TABLE` needs an **`ACCESS EXCLUSIVE`** lock on the table: nobody else
may read or write it while the change is made. An ordinary `SELECT` holds an `ACCESS SHARE` lock
for as long as its transaction lasts, and the two conflict. So the `ALTER` waits for the `SELECT`.
That part is expected. The part that surprises people is the next one: **every query that arrives
after the `ALTER` waits behind it**, even a `SELECT` that would not conflict with the first
`SELECT` at all. PostgreSQL grants locks in the order they were asked for, so nothing jumps the
queue past a waiting `ACCESS EXCLUSIVE`.

## A copy to work on

This lesson changes a table, so it works on a copy of `orders` rather than on `orders` itself.
Every later lesson expects `shop` as lesson 4 left it, and the last section drops the copy:

```
ana@db:~$ psql shop
shop=# \timing on
shop=# CREATE TABLE orders_live AS SELECT * FROM orders;
shop=# \q
```

A million rows, copied in under a second on the recording machine. `CREATE TABLE … AS` copies the
columns and the rows and nothing else: no primary key, no index, no `NOT NULL`. The section on
constraints puts the primary key back without blocking anybody.

## Three terminals

Open three terminals on the server and run `psql shop` in each. Ask each one for its process id
first, so you can tell them apart later. The first one starts a transaction and reads the table,
the way a report or a slow page does, and then stays inside the transaction:

```
ana@db:~$ psql shop
shop=# SELECT pg_backend_pid();
shop=# BEGIN;
shop=*# SELECT count(*) FROM orders_live;
```

The `*` in `shop=*#` is psql saying a transaction is open. The `SELECT` has finished, and its lock
has not been released: **a lock lasts until the end of the transaction**, not the end of the
statement.

In the second terminal, the schema change. Adding a column with no default is one of the cheapest
changes there is, as the section after next measures:

```
ana@db:~$ psql shop
shop=# SELECT pg_backend_pid();
shop=# \timing on
shop=# ALTER TABLE orders_live ADD COLUMN note text;
```

It does not come back. And in the third terminal, the kind of query a website sends a hundred times
a second:

```
ana@db:~$ psql shop
shop=# SELECT pg_backend_pid();
shop=# \timing on
shop=# SELECT status FROM orders_live WHERE id = 1;
```

That does not come back either.

## Seeing it

A fourth terminal can see the whole queue. `pg_stat_activity` has a row per connection, and
`pg_blocking_pids()` names the processes a given process is waiting for:

```
ana@db:~$ psql shop
shop=# SELECT pid, pg_blocking_pids(pid) AS blocked_by, state, wait_event_type, wait_event, left(query, 45) AS query FROM pg_stat_activity WHERE datname = 'shop' AND pid <> pg_backend_pid() ORDER BY backend_start;
shop=# SELECT pid, mode, granted FROM pg_locks WHERE relation = 'orders_live'::regclass ORDER BY granted DESC, pid;
```

Read it from the top:

- The first session is **`idle in transaction`**. It is doing nothing at all, and it holds an
  `AccessShareLock` that was granted.
- The `ALTER` is `active` and waiting: `wait_event_type` is `Lock` and `wait_event` is `relation`,
  a lock on a table. `blocked_by` names the first session.
- The `SELECT` is waiting too, and **`blocked_by` names the `ALTER`**, not the first session. Its
  `AccessShareLock` does not conflict with the one already granted; it conflicts with the
  `AccessExclusiveLock` queued ahead of it.

`pg_locks` says the same thing in one column: `granted` is `t` for the lock the first session holds
and `f` for the two behind it. On a busy table that `f` list grows by every query that arrives,
connections pile up until `max_connections` refuses the next one, and the site is down while the
`ALTER` has not yet done anything.

## Letting it go

Commit in the first terminal:

```
shop=*# COMMIT;
```

The `ALTER` gets its lock, adds the column in a moment, and releases it; the `SELECT` runs right
after. Look back at the second and third terminals: each reports `Time:` in seconds, and nearly all
of it was waiting. The work itself took milliseconds.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"A timeline of three sessions. Session 1 holds a shared lock until it commits. Session 2, the ALTER, waits from its arrival until that commit, then runs for a moment. Session 3 arrives after the ALTER and waits behind it, though it does not conflict with session 1, and runs only after the ALTER finishes.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"16\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">1  the report</text><line x1=\"150\" y1=\"40\" x2=\"700\" y2=\"40\" stroke=\"var(--scan)\" stroke-width=\"1\"></line><text x=\"16\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">2  the ALTER</text><line x1=\"150\" y1=\"90\" x2=\"700\" y2=\"90\" stroke=\"var(--scan)\" stroke-width=\"1\"></line><text x=\"16\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">3  a page view</text><line x1=\"150\" y1=\"140\" x2=\"700\" y2=\"140\" stroke=\"var(--scan)\" stroke-width=\"1\"></line><rect x=\"160\" y=\"28\" width=\"360\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">holds ACCESS SHARE, idle in transaction</text><rect x=\"250\" y=\"78\" width=\"270\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"260\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">waits for ACCESS EXCLUSIVE</text><rect x=\"520\" y=\"78\" width=\"14\" height=\"24\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">runs</text><rect x=\"330\" y=\"128\" width=\"204\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"340\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">waits behind the ALTER</text><rect x=\"534\" y=\"128\" width=\"10\" height=\"24\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">runs</text><line x1=\"520\" y1=\"18\" x2=\"520\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 3\"></line><text x=\"520\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">COMMIT</text><line x1=\"150\" y1=\"200\" x2=\"700\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"700\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "The ALTER needs a few milliseconds of work and waits seconds for its lock. Everything that arrives after it waits as long, which is the outage."}
```

**The danger is never only the `ALTER`.** It is the `ALTER` multiplied by whatever is holding the
table when it arrives, and the long transaction you did not know about is the usual culprit.
`db-performance` lessons 12 and 13 go through lock modes in depth and how to find a blocker on a
busy server; the next section is the habit that makes a schema change safe to try without knowing
in advance.
