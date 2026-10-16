---
title: Every statement locks the table
version: 1
---

The usual picture of locking in PostgreSQL is that readers never lock anything and writers lock
the rows they change. **Half of that is true and the other half causes outages.** Readers do not
block writers on the rows, and that is the multiversion design `sql-databases` lesson 8 described.
But every statement, the plainest `SELECT` included, also takes a lock on each table it touches,
and holds it until its transaction ends. Most of those locks never conflict with anything, which is
why nobody notices them, until a statement arrives that needs one of the few modes that conflicts
with all the rest.

## Watching one transaction's locks

Open two terminals and run `psql market` in each. This lesson calls them **window A** and **window
B**, and every transcript below is one window at one moment: type into the window the text names,
in the order the text gives. In window A, open a transaction and read some orders:

```
market=# BEGIN;
BEGIN
Time: 0.525 ms

market=*# SELECT count(*) FROM orders WHERE seller_id = 42;
 count 
-------
  1532
(1 row)

Time: 2.317 ms
```

The transaction is still open. In window B, ask the server which table locks other sessions hold
right now. `pg_locks` is the view lesson 13 reads properly; this is a first look at it:

```
market=# SELECT relation::regclass AS relation, mode, granted FROM pg_locks WHERE locktype = 'relation' AND pid <> pg_backend_pid() ORDER BY 1;
        relation        |      mode       | granted 
------------------------+-----------------+---------
 orders                 | AccessShareLock | t
 orders_pkey            | AccessShareLock | t
 orders_customer_id_idx | AccessShareLock | t
 orders_placed_at_idx   | AccessShareLock | t
 orders_seller_id_idx   | AccessShareLock | t
(5 rows)

Time: 2.104 ms
```

A single `SELECT` holds **`AccessShareLock` on `orders` and on all four of its indexes**: the
planner opened every index to decide whether to use it, and each of them stays locked until window
A's transaction ends. Back in window A, change one row, in the same transaction:

```
market=*# UPDATE orders SET status = 'shipped' WHERE id = 1;
UPDATE 1
Time: 1.173 ms
```

And look again from window B:

```
market=# SELECT relation::regclass AS relation, mode, granted FROM pg_locks WHERE locktype = 'relation' AND pid <> pg_backend_pid() ORDER BY 1;
        relation        |       mode       | granted 
------------------------+------------------+---------
 orders                 | RowExclusiveLock | t
 orders                 | AccessShareLock  | t
 orders_pkey            | AccessShareLock  | t
 orders_pkey            | RowExclusiveLock | t
 orders_customer_id_idx | RowExclusiveLock | t
 orders_customer_id_idx | AccessShareLock  | t
 orders_placed_at_idx   | RowExclusiveLock | t
 orders_placed_at_idx   | AccessShareLock  | t
 orders_seller_id_idx   | AccessShareLock  | t
 orders_seller_id_idx   | RowExclusiveLock | t
(10 rows)

Time: 0.932 ms
```

The `UPDATE` added **`RowExclusiveLock`** on the table and on every index it had to maintain, next
to the `AccessShareLock`s from before. Nothing is ever released early: a transaction collects locks
and gives all of them back at once, at `COMMIT` or `ROLLBACK`. **A long transaction is a long list
of locks**, which is the first reason to keep transactions short.

## Eight modes, and which pairs conflict

PostgreSQL has eight table lock modes. Their names are historical and say little; what matters is
which statements take each one, and which pairs cannot be held at the same time by two
transactions:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The table lock conflict matrix of PostgreSQL 16: eight modes from ACCESS SHARE, taken by SELECT, to ACCESS EXCLUSIVE, taken by ALTER TABLE, DROP, TRUNCATE and VACUUM FULL. ACCESS SHARE conflicts only with ACCESS EXCLUSIVE; ROW EXCLUSIVE, taken by INSERT, UPDATE and DELETE, conflicts with SHARE and everything stronger; ACCESS EXCLUSIVE conflicts with every mode, including ACCESS SHARE.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">held by one transaction (columns), asked for by another (rows)</text><text x=\"280\" y=\"36\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">held</text><text x=\"390\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">taken by</text><text x=\"196.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1</text><text x=\"220.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">2</text><text x=\"244.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">3</text><text x=\"268.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">4</text><text x=\"292.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5</text><text x=\"316.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">6</text><text x=\"340.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">7</text><text x=\"364.0\" y=\"54\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">8</text><text x=\"14\" y=\"74.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1 ACCESS SHARE</text><rect x=\"186\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"64\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"74.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SELECT</text><text x=\"14\" y=\"98.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2 ROW SHARE</text><rect x=\"186\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"88\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"98.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SELECT … FOR UPDATE / FOR SHARE</text><text x=\"14\" y=\"122.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3 ROW EXCLUSIVE</text><rect x=\"186\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"112\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"122.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">INSERT, UPDATE, DELETE</text><text x=\"14\" y=\"146.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4 SHARE UPDATE EXCLUSIVE</text><rect x=\"186\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"136\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"146.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">VACUUM, CREATE INDEX CONCURRENTLY</text><text x=\"14\" y=\"170.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">5 SHARE</text><rect x=\"186\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"160\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"170.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CREATE INDEX</text><text x=\"14\" y=\"194.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6 SHARE ROW EXCLUSIVE</text><rect x=\"186\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"184\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"194.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CREATE TRIGGER</text><text x=\"14\" y=\"218.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">7 EXCLUSIVE</text><rect x=\"186\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"208\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"218.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">REFRESH MATERIALIZED VIEW CONCURRENTLY</text><text x=\"14\" y=\"242.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">8 ACCESS EXCLUSIVE</text><rect x=\"186\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"210\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"234\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"258\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"306\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"330\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><rect x=\"354\" y=\"232\" width=\"20\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"390\" y=\"242.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ALTER TABLE, DROP, TRUNCATE, VACUUM FULL</text><rect x=\"14\" y=\"268\" width=\"16\" height=\"16\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"38\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conflict: the second one waits</text><rect x=\"250\" y=\"268\" width=\"16\" height=\"16\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"274\" y=\"276\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">no conflict: both go ahead</text></svg>", "caption": "Which table lock modes conflict. A filled square means a statement asking for the row's mode waits while another holds the column's."}
```

Read it row by row. A `SELECT` asks for `ACCESS SHARE`, row 1, and the only filled square in that
row is column 8: **a reader waits only for `ACCESS EXCLUSIVE`.** An `INSERT`, `UPDATE` or `DELETE`
asks for `ROW EXCLUSIVE`, row 3: it goes ahead next to any number of readers and other writers,
and waits for `SHARE` and the four modes above it. Row 8, `ACCESS EXCLUSIVE`, is filled all the
way across: **while it is held, or while it is waiting to be, nobody else touches the table.**
That last clause is the subject of section 04 of this lesson.

Two of those rows are worth knowing by heart. `CREATE INDEX` takes `SHARE`, which conflicts with
`ROW EXCLUSIVE`: it lets readers through and **stops every write for as long as the build runs**.
`CREATE INDEX CONCURRENTLY` takes `SHARE UPDATE EXCLUSIVE` instead, which does not conflict with
writes, and that is the whole reason it exists. Lesson 11's `DROP INDEX CONCURRENTLY` is the same
trade on the way out.

## A conflict, live

Window A still has its transaction open, holding `ROW EXCLUSIVE` from the update. In window B, build
an index on `orders`:

```
market=# CREATE INDEX orders_status_idx ON orders (status);
```

No answer and no prompt. **Window B is waiting**, and it will wait for as long as window A keeps its
transaction open: there is no timeout by default. Its `SHARE` is row 5, and column 3 of that row is
filled. Now end window A's transaction; this lesson rolls back, so that `orders` keeps the row as
`market.sql` wrote it:

```
market=*# ROLLBACK;
ROLLBACK
Time: 0.337 ms
```

The moment window A let go, window B's statement went ahead:

```
market=# CREATE INDEX orders_status_idx ON orders (status);
CREATE INDEX
Time: 8985.359 ms (00:08.985)
```

**8985 milliseconds**, of which the build itself was about one second, like the builds in lesson
11; the rest was waiting for window A. The `Time:` line counts from when the statement was sent,
so a wait shows up in it, and that is how a lock wait usually looks from outside: a statement that
is normally fast, taking a time that matches nothing about its own work. Drop the index again in
window B with `DROP INDEX orders_status_idx;` before going on.

Nothing about this conflict was an error. Both statements were correct, and the server did exactly
what the matrix says. **A table lock problem is almost never a bug in one statement; it is two
correct statements meeting in the wrong order**, and the rest of this lesson is about the meetings
worth expecting.
