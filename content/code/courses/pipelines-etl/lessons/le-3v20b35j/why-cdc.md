---
title: What a watermark cannot see
version: 1
---

Lesson 4 ended with three holes in incremental extraction, each found in the lab:

- **a delete leaves nothing behind**, so no `updated_at` can find it — customer 1880's erasure;
- **a row committed late hides below the watermark** — the slow till's order;
- **an update the source forgets to timestamp is invisible** for ever.

There is a fourth that the lab did not stage because it is quieter still. **A watermark sees each
row as it is now, not what happened to it.** An order placed at 10:00 and refunded at 15:00 is
extracted that night once, as refunded. The warehouse never learns that it was ever completed, and
a question like "how many sales were refunded the same day?" has no answer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-two-views\" aria-label=\"One order during one day. At 10:00 it is inserted as completed; at 15:00 it is updated to refunded. A watermark extraction at night reads the table once and sees one row, refunded. Change data capture reads the log and sees two changes, the insert and the update, in the order they committed.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">one order, one day</text><path d=\"M40.0 60.0 L680.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><circle cx=\"200.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"200.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10:00 INSERT completed</text><circle cx=\"420.0\" cy=\"60.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"420.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15:00 UPDATE refunded</text><path d=\"M620.0 48.0 L620.0 72.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"620.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">night</text><rect x=\"40.0\" y=\"130.0\" width=\"300.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">watermark: reads the table</text><rect x=\"80.0\" y=\"176.0\" width=\"220.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one row: refunded</text><rect x=\"380.0\" y=\"130.0\" width=\"300.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">change data capture: reads the log</text><rect x=\"400.0\" y=\"170.0\" width=\"125.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"462.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">INSERT</text><rect x=\"535.0\" y=\"170.0\" width=\"125.0\" height=\"24.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"597.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UPDATE</text><text x=\"530.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">two changes, in commit order</text></svg>", "caption": "A table holds the present. The log holds what happened, which is the only place the completed sale still exists."}
```


All four have the same cause: the pipeline is asking the *tables*, and a table only holds the
present. **Change data capture asks the database for its history instead** — every insert, update
and delete, in the order they were committed — and the database has been keeping that history all
along, for its own reasons.

## Where the history already is

Before PostgreSQL changes a single page of a table, it writes what it is about to do into the
**write-ahead log**, the WAL. That is how it survives a crash: after a power cut it replays the log
from the last checkpoint and arrives back where it was. Replicas are kept up to date the same way,
by receiving the log and replaying it.

The WAL is written for the database, in the database's own terms — pages, offsets, bytes — and is
of no direct use to a pipeline. **Logical decoding** is the feature that turns it back into rows:
*this transaction inserted this order, with these values*. A change data capture pipeline is a
reader of that stream, and it gets every change, deletes included, in commit order, with no query
against the tables at all.

The rest of this lesson builds one by hand against the shop, with nothing but PostgreSQL and
fifty lines of Python, and then says what the production tools for it — Debezium and Kafka Connect
among them — add on top.
