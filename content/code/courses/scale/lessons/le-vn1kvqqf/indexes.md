---
title: Building an index without stopping writes
version: 1
---

An index is the commonest change made to a table already in use, usually because a query got slow.
`CREATE INDEX` reads the whole table to build it, and while it does it holds a `SHARE` lock, which
lets reads through and **blocks every write**. Here it builds an index on `code` with sales
running in another terminal:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'CREATE INDEX tickets_code ON tickets (code)'
Timing is on.
CREATE INDEX
Time: 4408.653 ms (00:04.409)
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  558 in 8.0 s = 69.7 per second
latency   p50 10.2 ms  p95 76.7 ms  p99 95.1 ms  max 4453.8 ms
status    201: 558
```

The index took **4.4 seconds**, and the sales show it: **558 in eight seconds, the worst one 4.45
seconds**. Every sale that arrived during the build waited for it to finish.

`CREATE INDEX CONCURRENTLY` builds the same index without blocking writes. It takes the weaker
`SHARE UPDATE EXCLUSIVE` lock, reads the table once, then waits for transactions that might have
changed it, and reads again to catch up:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'CREATE INDEX CONCURRENTLY tickets_code ON tickets (code)'
Timing is on.
CREATE INDEX
Time: 5075.775 ms (00:05.076)
ana@lab:~/tickets$ python3 load.py -m POST -c 4 -d 8 --events 100 'http://localhost:8080/events/{event}/tickets'
requests  1275 in 8.1 s = 158.3 per second
latency   p50 15.2 ms  p95 71.9 ms  p99 79.6 ms  max 148.3 ms
status    201: 1275
```

**5.1 seconds instead of 4.4**, and **1275 sales with a worst case of 148 ms**, the same as with
nothing happening. Slower to build, invisible to the box office.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two runs of eight seconds of sales while an index is built on two million tickets. During CREATE INDEX, 558 sales went through and the slowest took 4.45 seconds, the length of the build. During CREATE INDEX CONCURRENTLY, 1275 sales went through and the slowest took 148 milliseconds.\"><text x=\"240\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sales in 8 s</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">slowest sale</text><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">CREATE INDEX</text><rect x=\"150\" y=\"50\" width=\"72.96923076923078\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"230.96923076923076\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">558</text><rect x=\"450\" y=\"50\" width=\"168.25466666666668\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"626.2546666666667\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4.45 s</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">… CONCURRENTLY</text><rect x=\"150\" y=\"130\" width=\"166.73076923076923\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"324.7307692307692\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1275</text><rect x=\"450\" y=\"130\" width=\"5.602444444444445\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"463.6024444444445\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">148 ms</text></svg>", "caption": "The same index, built two ways, measured from the box office's side."}
```

## What concurrently costs

- **It is slower and does more work**, two passes over the table and waits in between, which on a
  busy table can mean much longer than the plain build.
- **It cannot run inside a transaction block**, so a migration tool that wraps every migration in a
  transaction needs to be told to leave this one alone.
- **It can fail half-way**, for example when a unique index meets a duplicate. It then leaves an
  **invalid index** behind, marked `INVALID` in `\d tickets`, which slows every write and serves no
  query. Drop it with `DROP INDEX CONCURRENTLY` and build it again.
- **It waits for old transactions.** The long transaction of section 03 would hold it up too,
  without blocking anybody else.

`REINDEX CONCURRENTLY` rebuilds an existing index the same way, and `DROP INDEX CONCURRENTLY` removes
one without the `ACCESS EXCLUSIVE` lock that a plain `DROP INDEX` takes.
