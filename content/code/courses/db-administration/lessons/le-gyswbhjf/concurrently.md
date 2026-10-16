---
title: REINDEX CONCURRENTLY, and what a failed one leaves behind
version: 1
---

`REINDEX CONCURRENTLY` gets the same result by a longer road. **It builds a new index beside the old
one, under a lock that lets reads and writes carry on, and swaps the two at the end.** Readers keep
using the old index the whole time, writers keep both up to date once the new one exists, and
nobody queues.

The price is time and work. Timed one after the other on the same index:

```
shop=# \timing on
Timing is on.

shop=# REINDEX INDEX orders_customer_id;
REINDEX
Time: 475.202 ms

shop=# REINDEX INDEX CONCURRENTLY orders_customer_id;
REINDEX
Time: 738.791 ms
```

739 ms against 475 on the recording machine, half as long again, because the table is read
twice and the build stops several times to wait for other transactions. It also cannot run
inside a transaction block, and not on the system catalogs. On a live table they are nearly always
worth paying.

## It waits for others, and nobody waits for it

The waiting is the part to see. Terminal 2 opens a transaction with an update in it and leaves it
open, the way an application with a slow request does:

```
shop=# BEGIN;
BEGIN

shop=*# UPDATE orders SET total_cents = total_cents WHERE id = 1;
UPDATE 1
```

Terminal 1, with `\timing on`, starts the rebuild, and it hangs:

```
shop=# REINDEX INDEX CONCURRENTLY orders_created_at;
REINDEX
Time: 5957.520 ms (00:05.958)
```

Terminal 3 meanwhile reads and writes the table as if nothing were happening, and then asks what
terminal 1 is doing:

```
shop=# SELECT count(*) FROM orders WHERE customer_id = 42;
 count 
-------
    20
(1 row)

Time: 1.502 ms

shop=# UPDATE orders SET total_cents = total_cents WHERE id = 2;
UPDATE 1
Time: 2.347 ms

shop=# SELECT pid, wait_event_type, wait_event, pg_blocking_pids(pid) AS blocked_by, left(query, 50) AS query FROM pg_stat_activity WHERE datname = 'shop' AND pid <> pg_backend_pid();
 pid | wait_event_type | wait_event | blocked_by |                       query                        
-----+-----------------+------------+------------+----------------------------------------------------
 339 | Lock            | virtualxid | {343}      | REINDEX INDEX CONCURRENTLY orders_created_at;
 343 | Client          | ClientRead | {}         | UPDATE orders SET total_cents = total_cents WHERE 
(2 rows)

Time: 2.326 ms

shop=# SELECT phase FROM pg_stat_progress_create_index;
              phase               
----------------------------------
 waiting for writers before build
(1 row)

Time: 0.949 ms
```

The read and the write took milliseconds. The `REINDEX` is waiting on a `Lock` of the kind
`virtualxid`, **which is a wait for another transaction to end**, and `blocked_by` names terminal
2's process. `pg_stat_progress_create_index` says which step it is in: waiting for the writers that
were already running before the build. Every write that started before the new index existed has
to finish first, or it would be missing from the new index.

Terminal 2 commits:

```
shop=*# COMMIT;
COMMIT
```

and the `REINDEX` in terminal 1 finished at once, its `Time:` the whole time it waited. **The
danger of `CONCURRENTLY` is the opposite of a plain `REINDEX`: it never blocks the application, and
the application can stall it indefinitely**. A transaction left open in an idle session, lesson
10's `idle in transaction`, holds a concurrent rebuild for as long as it stays open.

## The steps, and where a failure leaves its mark

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 316\" role=\"img\" aria-label=\"REINDEX INDEX CONCURRENTLY as eight steps: create orders_created_at_ccnew marked invalid; wait for the writers already running; build it from a snapshot; wait for the writers again; add the rows written during the build; wait for older snapshots and mark it valid; swap the names so the old index becomes _ccold; wait, then drop _ccold. The timeout in this section hit step 2. A failure in steps 1 to 6 leaves orders_created_at_ccnew invalid: drop it and run the REINDEX again. A failure in steps 7 or 8 leaves _ccold invalid: the rebuild worked, so drop it.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">REINDEX INDEX CONCURRENTLY orders_created_at</text><rect x=\"20\" y=\"40\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1</text><text x=\"52\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">create orders_created_at_ccnew, marked invalid</text><rect x=\"20\" y=\"74\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text><text x=\"52\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">wait for the writers already running</text><text x=\"410\" y=\"87.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the timeout hit here</text><rect x=\"20\" y=\"108\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"121.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">3</text><text x=\"52\" y=\"121.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build _ccnew from a snapshot of the table</text><rect x=\"20\" y=\"142\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">4</text><text x=\"52\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">wait for the writers again</text><rect x=\"20\" y=\"176\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5</text><text x=\"52\" y=\"189.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">add the rows written during the build</text><rect x=\"20\" y=\"210\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">6</text><text x=\"52\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">wait for older snapshots, mark _ccnew valid</text><rect x=\"20\" y=\"244\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">7</text><text x=\"52\" y=\"257.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">swap the names: the old index becomes _ccold</text><rect x=\"20\" y=\"278\" width=\"400\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"291.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">8</text><text x=\"52\" y=\"291.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">wait, then drop _ccold</text><path d=\"M 434 40 L 442 40 L 442 236 L 434 236\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"452\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a failure in steps 1 to 6</text><text x=\"452\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">leaves the new copy behind:</text><text x=\"452\" y=\"146.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders_created_at_ccnew INVALID</text><text x=\"452\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">drop it, then run the REINDEX again</text><path d=\"M 434 244 L 442 244 L 442 304 L 434 304\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"452\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a failure in 7 or 8</text><text x=\"452\" y=\"266.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">leaves the old one behind:</text><text x=\"452\" y=\"282.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">_ccold INVALID</text><text x=\"452\" y=\"298.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the rebuild worked; drop it</text></svg>", "caption": "Each step commits on its own, which is how the other sessions keep working, and also why a failure leaves something behind. Which leftover depends on whether the names had been swapped."}
```

Each step commits before the next starts, which is what lets other sessions work in between. It is
also why stopping it halfway does not undo it: the steps already committed stay committed.

To fail it on purpose, terminal 2 holds an update open again, and terminal 1 gives the rebuild five
seconds:

```
shop=# BEGIN;
BEGIN

shop=*# UPDATE orders SET total_cents = total_cents WHERE id = 1;
UPDATE 1
```

```
shop=# SET statement_timeout = '5s';
SET

shop=# REINDEX INDEX CONCURRENTLY orders_created_at;
ERROR:  canceling statement due to statement timeout
```

Terminal 2 gives up its transaction:

```
shop=*# ROLLBACK;
ROLLBACK
```

and terminal 1 looks at the table:

```
shop=# RESET statement_timeout;
RESET

shop=# \d orders
                                    Table "public.orders"
   Column    |           Type           | Collation | Nullable |           Default            
-------------+--------------------------+-----------+----------+------------------------------
 id          | bigint                   |           | not null | generated always as identity
 customer_id | bigint                   |           | not null | 
 status      | text                     |           | not null | 
 total_cents | integer                  |           | not null | 
 created_at  | timestamp with time zone |           | not null | 
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
    "orders_created_at" btree (created_at)
    "orders_created_at_ccnew" btree (created_at) INVALID
    "orders_customer_id" btree (customer_id)
Foreign-key constraints:
    "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id)

shop=# SELECT indexrelid::regclass, indisvalid FROM pg_index WHERE NOT indisvalid;
       indexrelid        | indisvalid 
-------------------------+------------
 orders_created_at_ccnew | f
(1 row)

shop=# DROP INDEX CONCURRENTLY orders_created_at_ccnew;
DROP INDEX

shop=# SELECT count(*) FROM pg_index WHERE NOT indisvalid;
 count 
-------
     0
(1 row)
```

**`orders_created_at_ccnew ... INVALID` is the new copy, created in step 1 and abandoned in step 2.**
The original `orders_created_at` is untouched and still in use. The invalid one is never used by a
query, and once it has got as far as being kept up to date it costs something on every write, so it
is not harmless to leave. The query on `pg_index` finds every invalid index in a database, and it
belongs in a routine check, because a failed rebuild in the night says so only in a log.

The cure depends on the suffix. **A `_ccnew` is dropped and the `REINDEX CONCURRENTLY` run again.**
A `_ccold` means the failure came after the swap: the new index is already in place under the
original name, the rebuild worked, and only the old copy is left to drop. `DROP INDEX CONCURRENTLY`
removes either without blocking the table, and the last query says nothing invalid is left.
