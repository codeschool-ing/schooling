---
title: The lock queue, and the ALTER that stopped every read
version: 1
---

Here is the outage this section is about. Somebody adds a column to a table, a statement that
would take two milliseconds, and for the next fifteen seconds **every query on that table waits**,
including plain reads that conflict with nothing anybody holds. The intuition that fails
is that a statement waits only for locks that conflict with its own. It also waits for **every
statement that asked before it** and is still waiting itself.

## Three windows

Open a third terminal with `psql market`, window C. In window A, start something that reads
`orders` for a while; here `pg_sleep(15)` stands in for a slow report:

```
market=# SELECT pg_sleep(15), status FROM orders WHERE id = 1;
```

About a second later, in window B, add a column. Adding a nullable column with no default
changes only the catalogue and takes milliseconds. But `ALTER TABLE` needs `ACCESS EXCLUSIVE`, row
8 of the matrix in section 02 of this lesson, and that conflicts with window A's `ACCESS SHARE`:

```
market=# ALTER TABLE orders ADD COLUMN gift_note text;
```

A second after that, in window C, read one order, the cheapest query there is:

```
market=# SELECT status FROM orders WHERE id = 2;
```

All three are waiting. Window A is working; windows B and C have no prompt. Wait for window A to
finish:

```
market=# SELECT pg_sleep(15), status FROM orders WHERE id = 1;
 pg_sleep | status  
----------+---------
          | shipped
(1 row)

Time: 15018.259 ms (00:15.018)
```

```
market=# ALTER TABLE orders ADD COLUMN gift_note text;
ALTER TABLE
Time: 13507.137 ms (00:13.507)
```

```
market=# SELECT status FROM orders WHERE id = 2;
  status   
-----------
 delivered
(1 row)

Time: 12001.566 ms (00:12.002)
```

**Window C waited 12.0 seconds to read one row.** Its `ACCESS SHARE` does not conflict with window
A's `ACCESS SHARE`; nothing window A held stood in its way. What stood in its way was window B.

## Why C waited

Each table has a queue of lock requests that could not be granted at once. **A new request is
granted only if it conflicts with nobody holding the lock and nobody already waiting in the
queue.** The second condition is what keeps a strong lock from waiting forever: if readers could
jump the queue, a busy table would always have some reader holding `ACCESS SHARE`, and an
`ALTER TABLE` would never get in. So the server makes everybody line up behind the waiting
`ALTER`, and the waiting `ALTER` is waiting for the slow report:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 232\" role=\"img\" aria-label=\"A timeline of three windows over about fifteen seconds. Window A runs a SELECT for 15.0 seconds, holding ACCESS SHARE on orders. Window B asks for ACCESS EXCLUSIVE to add a column about a second and a half later and waits 13.5 seconds. Window C asks for ACCESS SHARE to read one order three seconds in and waits 12.0 seconds, behind B, although its lock does not conflict with A&#x27;s. When A ends, B runs and C runs straight after.\"><text x=\"14\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">window A</text><text x=\"14\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SELECT pg_sleep(15)…</text><rect x=\"150\" y=\"40\" width=\"510.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"158\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">holds ACCESS SHARE</text><text x=\"14\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">window B</text><text x=\"14\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ALTER TABLE … ADD COLUMN</text><rect x=\"201.0\" y=\"92\" width=\"459.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"209.0\" y=\"104\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">waits 13.5 s for ACCESS EXCLUSIVE</text><rect x=\"660.0\" y=\"92\" width=\"8\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"14\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">window C</text><text x=\"14\" y=\"174\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SELECT status … id = 2</text><rect x=\"252.0\" y=\"144\" width=\"408.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"260.0\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">waits 12.0 s behind B</text><rect x=\"660.0\" y=\"144\" width=\"8\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><path d=\"M150 196 L694 196\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M150 196 L150 201\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"150\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">0 s</text><path d=\"M320 196 L320 201\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"320\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">5 s</text><path d=\"M490 196 L490 201\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"490\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">10 s</text><path d=\"M660 196 L660 201\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"660\" y=\"212\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">15 s</text><path d=\"M660 34 L660 196\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1\"></path><text x=\"656\" y=\"24\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">A ends: B, then C</text></svg>", "caption": "The lock queue. C does not conflict with A, but it arrived after B, and B is waiting for A."}
```

The `ALTER` itself, once granted, took a couple of milliseconds, and everything behind it went in a
burst. On a real table the queue behind window B is not one `SELECT`; it is every request the
application sends during those fifteen seconds, each holding a connection while it waits. Lesson
16 shows what happens when the connections run out first.

Remove the column in window B with `ALTER TABLE orders DROP COLUMN gift_note;` before going on.

## The defence: `lock_timeout`

The waiting is the problem, not the `ALTER`. So limit how long a strong lock may wait:
**`lock_timeout`** makes a statement give up if it has not been granted its lock within that time,
which also takes it out of the queue and lets everybody behind it through. Start the slow report
again in window A, then, in window B:

```
market=# ALTER TABLE orders DROP COLUMN gift_note;
ALTER TABLE
Time: 2.701 ms

market=# SET lock_timeout = '2s';
SET
Time: 0.437 ms

market=# ALTER TABLE orders ADD COLUMN gift_note text;
ERROR:  canceling statement due to lock timeout
Time: 2000.845 ms (00:02.001)
```

And window C, which asked for its read half a second after window B's `ALTER` started waiting:

```
market=# SELECT status FROM orders WHERE id = 2;
  status   
-----------
 delivered
(1 row)

Time: 1088.808 ms (00:01.089)
```

**The `ALTER` gave up after exactly two seconds, and window C waited 1089 ms instead of 12,002.**
The schema change did not happen, which is the honest outcome: it can be tried again a minute later,
when the report has finished, and until then the application only noticed a two-second hiccup.

In practice that means three habits for any statement that takes `ACCESS EXCLUSIVE` on a busy
table — `ALTER TABLE`, `DROP INDEX` without `CONCURRENTLY`, `TRUNCATE`:

- **Set `lock_timeout` in the same session first**, a few seconds at most.
- **Retry in a loop** until it gets in, rather than raising the timeout; `db-administration`
  lesson 22 builds that loop for a live migration.
- **Look for long transactions before starting**, because they are what the `ALTER` would queue
  behind; lesson 13 is about finding them while they are happening.

`statement_timeout` is not a substitute. It limits how long a statement runs in total, waiting
included, so it would also cut off the slow report; `lock_timeout` only limits the wait for a lock,
and it is aimed at exactly the statement that would otherwise hold up the queue.
