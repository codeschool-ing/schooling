---
title: The lock queue
version: 1
---

Adding a nullable column is one of the fastest changes there is: PostgreSQL records it in the
catalogue and touches no row. It still needs `ACCESS EXCLUSIVE` for that instant. Here is what
happens when it cannot have it at once.

Three terminals. In the first, a long transaction that has read the table: a slow report, or a
session somebody left open with `BEGIN` and walked away from. Here it counts the tickets and then
sleeps twenty seconds before committing:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c 'BEGIN' -c 'SELECT count(*) FROM tickets' -c 'SELECT pg_sleep(20)' -c 'COMMIT'
BEGIN
  count  
---------
 2000000
(1 row)

 pg_sleep 
----------
 
(1 row)

COMMIT
```

In a second terminal, two seconds later, the column, with `\timing` so that psql says how long it
took:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ADD COLUMN gate text'
Timing is on.
ALTER TABLE
Time: 18057.004 ms (00:18.057)
```

And in a third, one second after that, eight seconds of sales:

```
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  4 in 10.0 s = 0.4 per second
status    TimeoutError: 4
```

**Four requests, all of them timed out, and not one ticket sold in ten seconds.** The `ALTER TABLE`
itself reported **18.1 seconds**, for a change that takes a few milliseconds of work.

## Who was waiting for whom

While all three were running, a fourth command asked PostgreSQL what every active connection was
doing:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pid, wait_event_type, wait_event, left(query, 40) AS query FROM pg_stat_activity WHERE datname = 'tickets' AND state = 'active' AND pid <> pg_backend_pid() ORDER BY backend_start"
 pid | wait_event_type | wait_event |                  query                   
-----+-----------------+------------+------------------------------------------
 201 | Timeout         | PgSleep    | SELECT pg_sleep(20)
 217 | Lock            | relation   | ALTER TABLE tickets ADD COLUMN gate text
 218 | Lock            | relation   | INSERT INTO tickets (event_id, seat, cod
 219 | Lock            | relation   | INSERT INTO tickets (event_id, seat, cod
 220 | Lock            | relation   | INSERT INTO tickets (event_id, seat, cod
 221 | Lock            | relation   | INSERT INTO tickets (event_id, seat, cod
(6 rows)
```

Read it from the top. The long transaction sleeps, holding `ACCESS SHARE` on `tickets` since its
`SELECT`. The `ALTER TABLE` waits on a `Lock` of type `relation`: it wants `ACCESS EXCLUSIVE`, which
conflicts with that `ACCESS SHARE`. And **four `INSERT`s wait behind the `ALTER`**, although an
`INSERT`'s lock does not conflict with the long transaction at all.

That is the **lock queue**. PostgreSQL grants locks in the order they are requested, and a request
that conflicts with one **already waiting** waits too, so that the `ALTER` is not starved by a
stream of newcomers. The consequence is that a schema change waiting for a lock **blocks everybody
who arrives after it**, for as long as it waits, even though it has done nothing yet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The lock queue on the tickets table. At the front, the long transaction holds ACCESS SHARE. Behind it, the ALTER TABLE waits for ACCESS EXCLUSIVE, which conflicts with it. Behind the ALTER, four INSERTs wait for ROW EXCLUSIVE: their lock does not conflict with the long transaction, but it conflicts with the ALTER waiting ahead of them, so they queue too.\"><rect x=\"20\" y=\"90\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">long transaction</text><text x=\"95\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ACCESS SHARE</text><text x=\"95\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">holds</text><rect x=\"230\" y=\"90\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"315\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">ALTER TABLE</text><text x=\"315\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ACCESS EXCLUSIVE</text><text x=\"315\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">waits 18 s</text><path d=\"M230 125 L172 125\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M172 125 L178.3 122.0 L178.3 128.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><rect x=\"470\" y=\"30\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><text x=\"545\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ROW EXCLUSIVE</text><path d=\"M470 49 L402 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402 125 L403.9 118.3 L408.5 122.3 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"470\" y=\"80\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><text x=\"545\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ROW EXCLUSIVE</text><path d=\"M470 99 L402 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402 125 L406.8 119.9 L409.0 125.6 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"470\" y=\"130\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><text x=\"545\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ROW EXCLUSIVE</text><path d=\"M470 149 L402 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402 125 L409.0 124.2 L406.9 130.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"470\" y=\"180\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><text x=\"545\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ROW EXCLUSIVE</text><path d=\"M470 199 L402 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M402 125 L408.5 127.6 L404.0 131.7 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"545\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">wait behind the ALTER</text><text x=\"95\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SELECT, then sleep 20 s</text></svg>", "caption": "A change waiting for its lock blocks everyone who arrives after it, though it has done nothing yet."}
```

So the danger is not the change; it is the **combination** of a strong lock and anything long
running on the table, whose end nobody controls. The next section is the defence.
