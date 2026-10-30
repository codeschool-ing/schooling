---
title: Backfill, change data capture, and the two together
version: 1
---

**Moving data out of a live database is not a copy, because the database being copied does not
stop.** Quitanda's shop still runs on the PostgreSQL it started with, on a machine in a rented rack
at `198.51.100.20`, and orders arrive in it every minute of the day. Copying its tables takes hours.
By the time the last table lands in Google Cloud, the first one is hours out of date, and stopping
the shop for those hours is the thing the business will not accept. So the problem has two halves:
copying what is there, and then keeping up with what keeps changing.

**Google Cloud has three services that move data in, and they answer different questions.**

| service | what it does | when it is the answer |
|---|---|---|
| Datastream | copies a database's tables and then streams every change, into BigQuery or Cloud Storage | the warehouse or the lake should follow a live database within seconds |
| Database Migration Service | moves a database to Cloud SQL or AlloyDB, copying and then replicating until the cutover | the database itself is moving, and the applications go with it |
| BigQuery Data Transfer Service | loads data into BigQuery on a schedule, from Cloud Storage, other clouds, other warehouses and SaaS products | a nightly or hourly load is enough, and nobody needs every change |

This lesson is mostly about the first, because it is the one Quitanda needs first: the reports
should stop reading the shop's own database, and BigQuery, lessons 13 to 18, is where they should
read instead. The other two get a section of their own after the practice.

**Change data capture, CDC, is reading a database's own record of its changes.** Every serious
database writes each change to a log before it changes its tables, so that it can recover after a
crash: PostgreSQL calls it the write-ahead log, MySQL the binary log, Oracle the redo log, SQL
Server the transaction log. CDC reads that log from outside and turns it back into rows: this order
was inserted, that total was updated, this row was deleted. It never queries the tables for what
changed, which is why it costs the source little and misses nothing that was committed. Lesson 19's
topics carried events that somebody chose to publish; CDC is the same idea for a database that was
never designed to share them, and the section after next makes PostgreSQL do it for real.

## Backfill and CDC together

**Datastream calls the two halves backfill and CDC**, and a stream does one, the other or both.
*Backfill* is the copy of what the tables hold when the stream starts. *CDC* is every change from a
point in the log onwards. A stream created with `--backfill-all` does both, which is the usual
choice for a live database; one created with `--backfill-none` only streams changes, for tables
already loaded some other way.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A timeline of a Datastream stream with backfill and change data capture, in four rows. At the start the position in the source log is noted. The source keeps taking inserts, updates and deletes until the cutover, and is read-only after it. The backfill copies the tables in the first stretch. During that stretch the changes are captured and held back; when the copy ends they are applied, and from then on applied as they happen. The destination fills during the copy, then stays seconds behind the source, and takes the writes after the cutover.\" data-fig=\"l25g-timeline\"><defs><marker id=\"ah-l25g-timeline\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">source</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">backfill</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">changes</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">destination</text><rect x=\"140\" y=\"47\" width=\"450\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">writes go on: inserts, updates, deletes</text><rect x=\"590\" y=\"47\" width=\"120\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"650.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read-only</text><rect x=\"140\" y=\"97\" width=\"190\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tables copied</text><rect x=\"140\" y=\"137\" width=\"190\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"235.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">captured, held back</text><rect x=\"330\" y=\"137\" width=\"55\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"357.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">applied</text><rect x=\"385\" y=\"137\" width=\"205\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">applied as they happen</text><rect x=\"140\" y=\"187\" width=\"245\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"262.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">filling</text><rect x=\"385\" y=\"187\" width=\"205\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">seconds behind the source</text><rect x=\"590\" y=\"187\" width=\"120\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">takes the writes</text><line x1=\"140\" y1=\"30\" x2=\"140\" y2=\"225\" stroke=\"var(--paper)\" stroke-width=\"0.9\" stroke-dasharray=\"2 3\"></line><line x1=\"590\" y1=\"30\" x2=\"590\" y2=\"225\" stroke=\"var(--paper)\" stroke-width=\"0.9\" stroke-dasharray=\"2 3\"></line><text x=\"140\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">start: log position noted</text><text x=\"590\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cutover</text><line x1=\"140\" y1=\"245\" x2=\"710\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l25g-timeline)\"></line><text x=\"425.0\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time: hours of backfill, then days or weeks of CDC</text></svg>", "caption": "The log position is taken before the first table is read, so no change made during the backfill falls between copied and captured."}
```

**The order of those bars is what makes it safe.** When the stream starts, the reader first notes
where the source's log is, and only then begins copying tables. Every change made while a table is
being copied is captured and held back; when that table's copy is done, the held changes are
applied to it, and from then on changes flow as they happen. Because the starting point was taken
before the copy, nothing that changed during it can fall through the gap between "copied" and
"captured". The stream then runs for as long as you let it, days or months, with the destination a
few seconds behind the source.

## Where the stream writes

**A Datastream destination is BigQuery or Cloud Storage**, and the two are different products for
the same changes. **Into BigQuery**, Datastream keeps a table per source table and applies the
changes to it, so that a query sees the current state of every row, refreshed within a staleness you set. Or, in *append-only* mode, it writes every change as a new row, which keeps the history and
leaves the current state to a query. **Into Cloud Storage**, it writes the changes as files, Avro or
JSON, under a path per table and per time, rotating to a new file by size or by interval; something
else, a Dataflow job or a BigQuery external table of lesson 17, reads them from there.

**For Quitanda the destination is BigQuery, in merge mode**: the reports want orders as they are now,
and a few minutes of staleness is a price they will happily pay for never querying the shop again.
The next section builds the stream, and says what each of its pieces is.
