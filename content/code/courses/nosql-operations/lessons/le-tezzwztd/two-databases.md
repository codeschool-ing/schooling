---
title: The price of two databases
version: 1
---

The previous section's most common answer was "Redis beside Postgres". It is a good answer, and it
is **not free**: the second database is a second system to run, and the moment one business
operation writes to both, a new kind of failure exists that neither database can see.

## What two cost before anything breaks

- **Two backups, and two restore drills.** Lesson 11's dump and snapshot for one, lesson 13's RDB
  and AOF for the other, each restored on a calendar. A restore of one without the other gives a
  shop whose orders and counters describe different moments.
- **Two sets of skills on call.** Whoever is paged at three in the morning has to read lesson 20's
  signals for both, and the failure vocabulary of each is its own.
- **Two upgrades, two security patches, two places for access to be wrong**, and on a managed service
  two invoices (lesson 21).

None of that is a reason to refuse a second database. It is the price to write next to the reason
for adding one.

## The dual write

The shop sells a monitor. The order goes into Postgres, and the stock shown on the product page is
cached in Redis so that the page does not query Postgres on every view. The obvious code writes
both:

1. `COMMIT` the order and the new stock in Postgres;
2. `SET` the new stock in Redis.

**Between the two there is a gap, and anything can happen in it.** The process is killed by a
deploy; the network to Redis drops for a second; Redis is failing over (lesson 15). Postgres has
committed, Redis never heard, and the page goes on showing a monitor that is no longer there. Doing
it the other way round only changes which side is wrong. A retry does not close the gap either: the
process that would retry is the one that died.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Two timelines of the same sale. On the left, the dual write: the application commits the order in Postgres, then its write to Redis fails, and Redis keeps showing the old stock. On the right, the outbox: the application commits the order and an outbox row in one Postgres transaction; a relay reads the outbox row, sets the stock in Redis, and only then marks the row done.\"><defs><marker id=\"l22ob-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l22ob-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l22ob-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"160\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">dual write</text><text x=\"50\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app</text><line x1=\"50\" y1=\"50\" x2=\"50\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"160\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Postgres</text><line x1=\"160\" y1=\"50\" x2=\"160\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"270\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Redis</text><line x1=\"270\" y1=\"50\" x2=\"270\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"50\" y1=\"70\" x2=\"158\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"104\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">order + stock</text><line x1=\"160\" y1=\"95\" x2=\"52\" y2=\"105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"104\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">COMMIT ok</text><line x1=\"50\" y1=\"140\" x2=\"230\" y2=\"155\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-amber)\" stroke-dasharray=\"4 3\"></line><text x=\"140\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">SET stock: fails</text><text x=\"242\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--amber)\">×</text><text x=\"160\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Redis still shows 1 monitor</text><text x=\"520\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">transactional outbox</text><text x=\"380\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app</text><line x1=\"380\" y1=\"50\" x2=\"380\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"480\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Postgres</text><line x1=\"480\" y1=\"50\" x2=\"480\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"580\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">relay</text><line x1=\"580\" y1=\"50\" x2=\"580\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"670\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Redis</text><line x1=\"670\" y1=\"50\" x2=\"670\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"380\" y1=\"70\" x2=\"478\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"430\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">order + outbox row</text><line x1=\"480\" y1=\"95\" x2=\"382\" y2=\"105\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"430\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one COMMIT</text><line x1=\"580\" y1=\"140\" x2=\"482\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-paper-dim)\"></line><text x=\"530\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">read outbox</text><line x1=\"580\" y1=\"180\" x2=\"668\" y2=\"190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-phosphor)\"></line><text x=\"624\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">SET stock = 0</text><line x1=\"580\" y1=\"255\" x2=\"482\" y2=\"265\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l22ob-ah-paper-dim)\"></line><text x=\"530\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mark done</text><text x=\"575\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">if the relay dies here, it repeats the SET</text><line x1=\"500\" y1=\"205\" x2=\"660\" y2=\"205\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line></svg>", "caption": "The dual write leaves a gap no retry can close, because the process that would retry is the one that failed. The outbox moves the second write inside the first transaction, and a relay delivers it at least once."}
```

## The transactional outbox

The fix is to make the second write **part of the first transaction**, in the only database that
has transactions. Next to the order, in the same `COMMIT`, the application inserts a row into an
`outbox` table saying what must happen elsewhere: "set the stock of MN-330 to 0". Either both rows
exist or neither does; there is no gap.

A separate process, the **relay**, reads the outbox in order, applies each entry to Redis, and only
then marks it done. If the relay dies after `SET` and before marking, the entry is applied again
when it restarts, so **the delivery is at least once**. The entries are written so that applying
one twice does no harm: "set the stock to 0" twice is still 0, where "decrement the stock" twice is
wrong. Lesson 4 called this keeping copies honest; the outbox is the mechanism that does it across
two databases.

The relay is the queue of the previous section: `SELECT ... FOR UPDATE SKIP LOCKED` lets several
relays share the outbox without taking the same entry. **This lesson does not build the relay**; the
pieces it is made of, the transaction, the locked read and Redis's `SET`, were each run in this
course, and assembling them is application code in whatever language the shop is written in.

The other route reads the database's own change log instead of an outbox table, change data capture,
which lesson 14 of `streaming` teaches with Debezium. Both rest on the same idea: **the database that commits is the only one
allowed to decide that something happened**, and everything else follows it.
