---
title: Following the chain to its root
version: 1
---

A blocking problem is a graph: every waiting session points at the sessions it waits for. The
belief that wastes the first ten minutes of an incident is that **the session to deal with is the
one waiting longest, or the one whose query the application is complaining about.** It is neither.
Cancel window C, whose update of order 2 is what a user is staring at, and window B still waits
for window A, and the next update of order 2 queues behind window B again. The only session worth
acting on is the **root**: one that blocks somebody and waits for nobody.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The wait graph of the lesson&#x27;s chain. Window A, pid 5792, is idle in transaction and holds order 1. Window B, pid 5794, holds order 2 and waits for A&#x27;s transaction to release order 1. Window C, pid 5796, waits for B&#x27;s transaction to release order 2. A is the root: it waits for nobody, and both others wait because of it.\"><rect x=\"14\" y=\"60\" width=\"188\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"26\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">window A</text><text x=\"190\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">5792</text><text x=\"26\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">idle in transaction</text><text x=\"26\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">holds order 1</text><rect x=\"266\" y=\"60\" width=\"188\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"278\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">window B</text><text x=\"442\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">5794</text><text x=\"278\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">active, waiting</text><text x=\"278\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">holds order 2</text><rect x=\"518\" y=\"60\" width=\"188\" height=\"96\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"530\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">window C</text><text x=\"694\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" text-anchor=\"end\" fill=\"var(--phosphor)\">5796</text><text x=\"530\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">active, waiting</text><text x=\"530\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">holds no row yet</text><path d=\"M266 108 L206 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M206.0 108.0 L212.0 104.0 L212.0 112.0 Z\" fill=\"var(--amber)\"></path><text x=\"236\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">waits for order 1</text><path d=\"M518 108 L458 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M458.0 108.0 L464.0 104.0 L464.0 112.0 Z\" fill=\"var(--amber)\"></path><text x=\"488\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">waits for order 2</text><text x=\"14\" y=\"36\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the root: blocks somebody, waits for nobody</text></svg>", "caption": "Who waits for whom. Arrows point from the waiting session to the one it waits for; the root is the one with no arrow leaving it."}
```

With three sessions you can follow the arrows in `blocked.sql` by eye. With forty sessions in two
chains, one of them five deep behind an `ALTER TABLE` that is itself waiting for a report, you
cannot, and the incident is not the moment to try.

## The tree, as a query

`pg_blocking_pids` gives one step of the graph per session, so a **recursive query** can walk it.
It starts from the roots, the sessions with an empty `blocked_by` that appear in somebody else's,
and adds, at each step, every session whose `blocked_by` contains a session already found. It keeps the
path from the root, which sorts the result into a tree, indents it by depth and stops a cycle from
looping forever:

```sh
cat > ~/lock-tree.sql <<'SQL'
-- lock-tree.sql: who blocks whom, as a tree. Each root is a session that
-- blocks somebody and waits for nobody; under it, everybody waiting for
-- it, and everybody waiting for them.
WITH RECURSIVE tree AS (
    SELECT pid, ARRAY[pid] AS path
    FROM pg_stat_activity
    WHERE cardinality(pg_blocking_pids(pid)) = 0
      AND pid IN (SELECT unnest(pg_blocking_pids(pid)) FROM pg_stat_activity)
  UNION ALL
    SELECT a.pid, t.path || a.pid
    FROM tree AS t
    JOIN pg_stat_activity AS a ON t.pid = ANY (pg_blocking_pids(a.pid))
    WHERE a.pid <> ALL (t.path)
)
SELECT repeat('   ', cardinality(t.path) - 1) || t.pid AS pid,
       a.state,
       date_trunc('second', now() - a.xact_start) AS in_transaction,
       left(a.query, 45) AS last_query
FROM tree AS t
JOIN pg_stat_activity AS a USING (pid)
ORDER BY t.path;
SQL
```

`WITH RECURSIVE` has two halves joined by `UNION ALL`: the first `SELECT` produces the starting
rows, and the second is run again and again on the rows the previous round produced, until a round
produces none. `ARRAY[pid]` starts each path, `t.path || a.pid` extends it, and `a.pid <> ALL
(t.path)` refuses a session already on the path. Ordering by `t.path` puts every session right
under the one it waits for, because an array sorts element by element, the way a list of chapter
numbers does.

In window D:

```
market=# \i ~/lock-tree.sql
    pid     |        state        | in_transaction |                  last_query                   
------------+---------------------+----------------+-----------------------------------------------
 5792       | idle in transaction | 00:00:34       | UPDATE orders SET status = 'shipped' WHERE id
    5794    | active              | 00:00:32       | UPDATE orders SET status = 'shipped' WHERE id
       5796 | active              | 00:00:27       | UPDATE orders SET status = 'cancelled' WHERE 
(3 rows)

Time: 3.882 ms
```

**5792 at the root, 5794 under it, 5796 under that.** The root is idle in transaction and has been
for 34 seconds; everything under it is active and waiting. That is the most common shape a lock
incident takes, and the tree shows it in one screen however many sessions are involved.

## Two shapes the tree can take

A session can wait for **more than one** session at once: an `ALTER TABLE` that needs `ACCESS
EXCLUSIVE` waits for every session holding any lock on the table, and its `blocked_by` lists them
all. It then appears in the tree once under each of them, which is correct: ending any one of them
is not enough to let it through.

A **deadlock** never shows up as a tree for long. Every session in a cycle waits for somebody, so
none of them has an empty `blocked_by`, none of them is a root, and the query returns nothing for
them. Within `deadlock_timeout`, one second here, the server breaks the cycle itself, as lesson 12
section 06 showed. A tree that persists is never a deadlock: **it is a session at the root that is
not going to finish by itself**, and the next section is about what to do with it.

## Why `pg_blocking_pids` and not a join

You will find versions of this query on the internet that join `pg_locks` to itself on
`transactionid`, `relation` and the rest. They miss cases the server does not: a session waiting
in the queue behind another waiter, which lesson 12 section 04 showed with three windows, appears
in `pg_blocking_pids` and in no self-join. The function has a cost, since it briefly locks the
server's lock tables to read them consistently, so it is for an incident or a monitoring query once
a minute, not for every page load.
