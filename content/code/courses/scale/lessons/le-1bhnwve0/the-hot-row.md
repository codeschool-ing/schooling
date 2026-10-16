---
title: The hot row, where neither direction helps
version: 1
---

Everything so far spread the sales over a hundred shows. A real ticket drop does the opposite: at
ten in the morning one show goes on sale and every buyer wants **that one**. Here is the same test,
16 workers, with every sale for show 1, against the three copies of the last section:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 'http://localhost:8080/events/1/tickets'
requests  1398 in 10.1 s = 138.3 per second
latency   p50 80.7 ms  p95 351.5 ms  p99 527.8 ms  max 814.9 ms
status    201: 1398
```

138 a second, where the same three copies sold 470 across a hundred shows. And with the copies
scaled back to one:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 16 -d 10 'http://localhost:8080/events/1/tickets'
requests  1391 in 10.1 s = 137.2 per second
latency   p50 80.7 ms  p95 327.7 ms  p99 521.8 ms  max 753.3 ms
status    201: 1391
```

137 a second. **Three copies sell exactly what one does.** The extra copies are not broken and not
idle; they are waiting.

## Waiting for what

PostgreSQL can say what every connection is doing at this moment. Run while the test above was
going, a count of the active connections by what they were waiting for:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT wait_event_type, wait_event, count(*) FROM pg_stat_activity WHERE datname = 'tickets' AND state = 'active' GROUP BY 1, 2 ORDER BY 3 DESC"
 wait_event_type |  wait_event   | count 
-----------------+---------------+-------
 Lock            | transactionid |    15
                 |               |     1
(2 rows)
```

Fifteen connections waiting on a `Lock` of type `transactionid`, and one doing work. **Fifteen
sales waiting for one other sale to finish**, because of one line in `app.py`:

```sql
UPDATE events SET sold = sold + 1 WHERE id = %s AND sold < capacity RETURNING sold
```

An `UPDATE` locks the row it changes until its transaction ends, so that two sales cannot both read
`sold = 41` and both write `42`. That is correct and necessary: it is what stops the box office
selling seat 42 twice. What makes it expensive is **how long the lock is held**. The transaction
updates the row, then calls `sign()`, about 7 ms of processor time, then inserts the ticket, and
only then commits. Every sale for show 1 holds the show's row for those 7 ms, and the next sale for
show 1 cannot start until it is released.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A timeline of three sales of show 1. Sale A runs UPDATE, holds the row's lock while it signs for about 7 milliseconds, inserts the ticket and commits. Sale B arrives during A's signing and waits until A commits, then does the same. Sale C waits for A and then for B. The row is held by one sale at a time, so the sales go one after another.\"><path d=\"M120 200 L700 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"190\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3.5</text><text x=\"260\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"330\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.5</text><text x=\"400\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><text x=\"470\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">17.5</text><text x=\"540\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21</text><text x=\"610\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">24.5</text><text x=\"680\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">28</text><text x=\"700\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ms</text><text x=\"60\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sale A</text><rect x=\"120.0\" y=\"40\" width=\"140.0\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"190.0\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">row locked: sign()</text><path d=\"M260.0 36 L260.0 68\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"266.0\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">COMMIT</text><text x=\"60\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sale B</text><rect x=\"176.0\" y=\"94\" width=\"84.0\" height=\"16\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"218.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waits</text><rect x=\"260.0\" y=\"90\" width=\"140.0\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"330.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">row locked: sign()</text><path d=\"M400.0 86 L400.0 118\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"406.0\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">COMMIT</text><text x=\"60\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sale C</text><rect x=\"218.0\" y=\"144\" width=\"182.0\" height=\"16\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></rect><text x=\"309.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waits</text><rect x=\"400.0\" y=\"140\" width=\"140.0\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">row locked: sign()</text><path d=\"M540.0 136 L540.0 168\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"546.0\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">COMMIT</text></svg>", "caption": "Three sales of the same show. Each holds the row for the whole of sign(), so each waits for all the ones before it."}
```

So the box office sells at most one ticket for a show every 7 ms or so, which is 1000 ÷ 7.2 ≈ 139
a second, whatever is behind it. That is the number measured, with one copy and with three. **A
bigger machine does not help either**: `sign()` would run a little faster on a faster processor,
and nothing else would change, because the work is not waiting for a processor. It is waiting for
its turn.

## The general shape

A **hot spot** is a piece of state that a large share of the work has to change, one at a time: a
row, a counter, a key, a lock, a file. It turns any number of copies into one queue. It is the most
common reason a system that scaled in testing stops scaling in production, because tests spread
their load evenly and real users do not: everybody wants the same concert, the same product on
sale, the same trending post.

There are three ways out, and each costs something:

- **Hold it for less time.** Signing does not need the lock; only choosing the seat does. Moving
  `sign()` and the insert after the commit would cut the time each sale holds the row to a
  fraction of a millisecond. The price is a moment when a seat is taken and its ticket does not
  exist yet, which the program now has to handle if it fails in between.
- **Split it.** Instead of one counter per show, keep ten, each owning a tenth of the seats, and
  let each sale pick one. Ten rows are ten queues. The price is that "how many are left" is now a
  sum, and the last few seats are scattered across counters. Lesson 2 does this to whole tables
  and calls it sharding.
- **Stop asking for it all at once.** Let the buyers queue outside the box office, and admit them
  at the rate the row can serve. That is what the waiting rooms of real ticket sites are, and
  lesson 9 builds the mechanism.

What does not work is adding copies, and that is the point of this section: **horizontal scaling
divides work that can be divided**, and it does nothing for the part that cannot.
