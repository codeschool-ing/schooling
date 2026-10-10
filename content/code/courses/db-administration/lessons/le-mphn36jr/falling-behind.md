---
title: One open transaction, and nothing is removed
version: 1
---

When a table keeps growing although autovacuum is on, the first guess is that autovacuum is too slow
and needs more workers. **Usually it is running fine and is not allowed to remove anything.** A
dead version may only go once no transaction could still see it, and the server answers that with
one number: the oldest snapshot any session still holds. Everything that died after that point
stays, in every table of the database, for as long as that snapshot stays open.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"A line of transaction ids from older on the left to newer on the right. A dashed line marks the oldest snapshot still open, held by a session idle in a transaction. Row versions that died to the left of it are removable and VACUUM reclaims them. Versions that died to the right of it are kept, because that session could still read them. When the session commits, the line moves to the present and those versions become removable too.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">transaction ids</text><line x1=\"20\" y1=\"150\" x2=\"690\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">older</text><text x=\"690\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">newer</text><rect x=\"40\" y=\"60\" width=\"290\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"56\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"88\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"120\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"152\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"184\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"216\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"248\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><rect x=\"280\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"185\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">died before the line</text><text x=\"185\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">VACUUM removes them</text><line x1=\"370\" y1=\"40\" x2=\"370\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></line><text x=\"370\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">oldest snapshot still open</text><text x=\"370\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">(the session idle in transaction)</text><rect x=\"410\" y=\"60\" width=\"290\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"426\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"458\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"490\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"522\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"554\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"586\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"618\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"650\" y=\"78\" width=\"22\" height=\"16\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"555\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">died after the line</text><text x=\"555\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">kept: that session may still read them</text><path d=\"M370 200 Q 520 222 680 200\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#arr)\"></path><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">after COMMIT the line jumps to the present, and everything to its left can go</text></svg>", "caption": "VACUUM may remove a dead version only if it died before the oldest snapshot anybody still holds. One idle transaction holds that line still for the whole database."}
```

The commonest holder is an application that opens a transaction, reads something and then waits:
for a person, for a remote call, for a bug to let go. You can make one with two terminals. In the
first, open a transaction at `REPEATABLE READ` and read the copy once, which fixes its snapshot, then
leave that terminal alone:

```
shop=# BEGIN ISOLATION LEVEL REPEATABLE READ;
BEGIN

shop=*# SELECT count(*) FROM orders_copy;
  count  
---------
 1000000
(1 row)
```

In the second, change 100,000 rows, find who holds a snapshot, and vacuum:

```
shop=# UPDATE orders_copy SET total_cents = total_cents + 1 WHERE id <= 100000;
UPDATE 100000

shop=# SELECT pid, state, backend_xmin, xact_start FROM pg_stat_activity WHERE backend_xmin IS NOT NULL;
 pid |        state        | backend_xmin |          xact_start           
-----+---------------------+--------------+-------------------------------
 448 | idle in transaction |          805 | 2026-10-10 16:42:50.024427-03
 458 | active              |          806 | 2026-10-10 16:42:51.424242-03
(2 rows)

shop=# VACUUM (VERBOSE, PROCESS_TOAST false) orders_copy;
INFO:  vacuuming "shop.public.orders_copy"
INFO:  finished vacuuming "shop.public.orders_copy": index scans: 0
pages: 0 removed, 10417 remain, 1670 scanned (16.03% of total)
tuples: 0 removed, 957677 remain, 100000 are dead but not yet removable
removable cutoff: 805, which was 1 XIDs old when operation ended
frozen: 0 pages from table (0.00% of total) had 0 tuples frozen
index scan not needed: 0 pages from table (0.00% of total) had 0 dead item identifiers removed
avg read rate: 0.000 MB/s, avg write rate: 0.525 MB/s
buffer usage: 3361 hits, 0 misses, 1 dirtied
WAL usage: 1 records, 1 full page images, 5949 bytes
system usage: CPU: user: 0.01 s, system: 0.00 s, elapsed: 0.01 s
VACUUM
```

**`100000 are dead but not yet removable`** is the line to know. VACUUM ran, read the pages,
removed nothing, and said why: `removable cutoff: 805` means it could remove only what died before
transaction 805, and `pg_stat_activity` shows whose number that is. The session in `idle in
transaction` has a `backend_xmin` of 805, the transaction id that was next when its snapshot was
taken. The 806 belongs to the second terminal itself, taken by the `SELECT` that was asking.

Autovacuum gets exactly the same answer. On a busy server it keeps visiting the table, because
`n_dead_tup` stays over the line, and every visit reads the pages and leaves the same dead versions
behind. **More workers would only read the same pages more often.** The fix is in the first
terminal:

```
shop=*# COMMIT;
COMMIT
```

Back in the second terminal, nobody is idle in a transaction any more, and the same VACUUM does its
job:

<<<falling-behind-after>>>

`100000 removed`, and `index scans: 1` because there were entries in the primary key to take out
this time. Nothing about the table changed between the two runs. Only the snapshot went away.

## What else holds the line

An idle transaction is the one you will meet most, and the query above finds it: `state` of `idle
in transaction` and an old `xact_start`. Lesson 10 shows how to end such a session and
`idle_in_transaction_session_timeout`, which ends it for you; db-performance lesson 15 is about long
transactions in depth.

A long-running query holds the line the same way while it runs, a report that takes three hours
included. So do two things that are not sessions at all, and that `pg_stat_activity` will not show:
**a prepared transaction** that nobody committed or rolled back, listed in `pg_prepared_xacts`, and
**a replication slot** whose consumer has stopped, listed in `pg_replication_slots` with an old
`xmin`. db-reliability lesson 11 explains slots. Here it is enough to know that when VACUUM says
`not yet removable` and no session is old, those two views are where to look next.
