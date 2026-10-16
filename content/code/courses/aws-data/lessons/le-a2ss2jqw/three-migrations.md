---
title: Full load, change data capture, and the two together
version: 1
---

**A migration is not a copy, because the database being copied does not stop.** Quitanda's shop
still runs on the PostgreSQL it started with, on a machine in a rented rack at `198.51.100.20`, and
orders arrive in it every minute of the day. Copying its tables takes hours. By the time the last
table lands in AWS, the first one is hours out of date, and stopping the shop for those hours is the
thing the business will not accept. Moving a live database is therefore two problems: copying what is
there, and then keeping up with what keeps changing.

**AWS Database Migration Service, DMS, solves them as three kinds of task**, and the kind is the
first decision:

| migration type | what it does | when it is the answer |
|---|---|---|
| `full-load` | copies every selected table once, as it is when each table is read | the source can stop writing for the copy, or the copy is a one-off snapshot |
| `cdc` | reads the source's changes from a point in time onwards and applies them | the tables are already on the target, loaded some other way |
| `full-load-and-cdc` | copies the tables, then applies every change made since the copy began, and keeps applying them | a live database moving with almost no downtime |

**Change data capture, CDC, is reading a database's own record of its changes.** Every serious
database writes each change to a log before it changes its tables, so that it can recover after a
crash: PostgreSQL calls it the write-ahead log, MySQL the binary log, Oracle the redo log, SQL Server
the transaction log. CDC reads that log from outside and turns it back into rows: this order was
inserted, that total was updated, this row was deleted. It never queries the tables for what
changed, which is why it costs the source little and misses nothing that was committed. Lesson 12
showed DynamoDB handing its changes to a stream; this is the same idea for a database that was never
designed to share them, and the section on PostgreSQL makes one do it for real.

## What full load and CDC look like together

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A timeline of a full-load-and-cdc task in four rows. At the start the position in the source log is noted. The source keeps taking inserts, updates and deletes until the cutover, and is read-only after it. The full load copies the tables in the first stretch. During that stretch the changes are captured and held back; when the copy ends they are applied, and from then on applied as they happen. The target fills during the copy, then stays seconds behind the source, and takes the writes after the cutover.\" data-fig=\"l26-timeline\"><defs><marker id=\"ah-l26-timeline\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">source</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">full load</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">changes</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">target</text><rect x=\"140\" y=\"47\" width=\"450\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">writes go on: inserts, updates, deletes</text><rect x=\"590\" y=\"47\" width=\"120\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"650.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">read-only</text><rect x=\"140\" y=\"97\" width=\"190\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tables copied</text><rect x=\"140\" y=\"137\" width=\"190\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"235.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">captured, held back</text><rect x=\"330\" y=\"137\" width=\"55\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"357.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">applied</text><rect x=\"385\" y=\"137\" width=\"205\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">applied as they happen</text><rect x=\"140\" y=\"187\" width=\"245\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"262.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">filling</text><rect x=\"385\" y=\"187\" width=\"205\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"487.5\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">seconds behind the source</text><rect x=\"590\" y=\"187\" width=\"120\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">takes the writes</text><line x1=\"140\" y1=\"30\" x2=\"140\" y2=\"225\" stroke=\"var(--paper)\" stroke-width=\"0.9\" stroke-dasharray=\"2 3\"></line><line x1=\"590\" y1=\"30\" x2=\"590\" y2=\"225\" stroke=\"var(--paper)\" stroke-width=\"0.9\" stroke-dasharray=\"2 3\"></line><text x=\"140\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">start: log position noted</text><text x=\"590\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">cutover</text><line x1=\"140\" y1=\"245\" x2=\"710\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#ah-l26-timeline)\"></line><text x=\"425.0\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time: hours of full load, then days or weeks of CDC</text></svg>", "caption": "The log position is taken before the first table is read, so no change made during the copy falls between copied and captured."}
```

**The order of those bars is the whole trick.** When the task starts, DMS first notes where the
source's log is, and only then begins copying tables. Every change made while a table is being
copied is captured and held back; when that table's copy finishes, the held changes are applied to
it, and from then on changes flow as they happen. Because the starting point was taken before the
copy, nothing that changed during it can fall through the gap between "copied" and "captured". The
task then runs for as long as you let it, days or weeks, with the target a few seconds behind the
source, until the moment you choose to move the applications across. That moment is the cutover, and
the last section of this lesson is about it.

## Where the work runs

**DMS needs somewhere to run the task, and there are two kinds of somewhere.** A **replication
instance** is a machine of a chosen class, `dms.t3.medium` or `dms.c5.large` in this course's sheet,
that you create, size and pay for by the hour whether a task is running on it or not; several tasks
can share one. **DMS Serverless** replaces the instance with a *replication config* that names a
minimum and a maximum of DMS capacity units, DCUs, and DMS scales between them as the load needs,
billing the DCU-hours used. The next section creates an instance in the lab, and tries the
serverless config too, which is where moto stops answering.

**Either way the machine sits between the two databases and needs to reach both.** For Quitanda that
means a network path from AWS to the rack, a VPN or a Direct Connect link, which is
`aws-foundations` lesson 24's subject, and a database user on the old PostgreSQL that is allowed to
read the tables and the log and nothing else.
