---
title: Attaching and detaching, and why dropping a month beats deleting it
version: 1
---

A partition is a table, and it can stop or start being one of the parent's without its rows moving.
`ATTACH PARTITION` takes a table that already exists and makes it a partition; `DETACH PARTITION`
makes a partition a table of its own again. Those two, and `DROP TABLE`, are the whole of how a
partitioned table ages, and they are where the job from section 02 is done.

## Adding next month, prepared in advance

`PARTITION OF`, as in section 03, creates the new table and attaches it in one statement. The other
way is to build the table on its own, load and index it while nobody can see it, and attach it when
it is ready:

```
market=# CREATE TABLE events_2026_02 (LIKE events_by_month INCLUDING DEFAULTS);
CREATE TABLE
Time: 5.217 ms

market=# ALTER TABLE events_2026_02 ADD CHECK (at >= '2026-02-01' AND at < '2026-03-01');
ALTER TABLE
Time: 2.380 ms

market=# ALTER TABLE events_by_month ATTACH PARTITION events_2026_02 FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
ALTER TABLE
Time: 6.529 ms
```

`LIKE events_by_month INCLUDING DEFAULTS` copies the columns. The `CHECK` constraint is the step that
makes the attach cheap, and it is easy to leave out: to attach a table, the server has to be sure
every row in it belongs to the interval, and without a constraint that proves it, it **reads the
whole table** to check, holding a lock while it does. With a constraint that matches the bound, it
reads the constraint instead. Here the table was empty, so either way took milliseconds; on a month
loaded in advance, the difference is a scan of every row, while the parent waits.

## Removing a month

Section 02 deleted October from `events` and measured it: **1611210 rows in three seconds, 251 MB
of WAL**, and a `ROLLBACK` to undo it. Here is the same month leaving `events_by_month`, with the WAL
measured the same way:

```
market=# SELECT pg_current_wal_lsn() AS before \gset
Time: 0.863 ms

market=# ALTER TABLE events_by_month DETACH PARTITION events_2025_10;
ALTER TABLE
Time: 2.703 ms

market=# DROP TABLE events_2025_10;
DROP TABLE
Time: 220.588 ms

market=# SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'before')) AS wal_written;
 wal_written 
-------------
 55 kB
(1 row)

Time: 0.582 ms
```

The detach took **2.7 milliseconds** and the drop **221**, which is the operating system removing
the files. The WAL written for both together was **55 kB**, against 251 MB, because the server
logged that a table went away and not each of its 1.6 million rows. There are no dead rows for
`VACUUM` to find, no index entries pointing at them, and no space left inside a file waiting to be
reused: the space is back on the disk the moment the drop commits.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two ways to remove October. Above, events as one table: a DELETE marks 1611210 rows dead inside the same file, writes 251 MB of WAL and takes about three seconds, and the file stays the same size. Below, events_by_month as four monthly partitions: October is detached from the parent and dropped as a whole file, writing 55 kB of WAL, while November, December and January stay attached.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one table: DELETE</text><rect x=\"14\" y=\"30\" width=\"560\" height=\"56\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"16\" y=\"32\" width=\"180\" height=\"52\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"106\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">October, marked dead</text><text x=\"106\" y=\"70\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">1611210 rows</text><text x=\"385\" y=\"58\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">November and December, the same file</text><text x=\"590\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">251 MB WAL</text><text x=\"590\" y=\"66\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2969 ms</text><text x=\"14\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partitioned by month: DETACH, then DROP</text><rect x=\"170\" y=\"140\" width=\"404\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"372\" y=\"155\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--paper)\">events_by_month</text><rect x=\"14\" y=\"214\" width=\"140\" height=\"40\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"84\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--amber)\">events_2025_10</text><rect x=\"204\" y=\"214\" width=\"118\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"263\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">events_2025_11</text><path d=\"M263 170 L263 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"328\" y=\"214\" width=\"118\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"387\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">events_2025_12</text><path d=\"M387 170 L387 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"452\" y=\"214\" width=\"118\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"511\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper)\">events_2026_01</text><path d=\"M511 170 L511 214\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M84 214 L84 190 L170 160\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><text x=\"14\" y=\"274\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">detached, then dropped whole</text><text x=\"590\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">55 kB WAL</text><text x=\"590\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2.7 + 221 ms</text></svg>", "caption": "Removing October, both ways, with the numbers from the two transcripts."}
```

The detach and the drop are two statements on purpose. Between them, `events_2025_10` is an ordinary
table that no query on the parent can see, which is the moment to copy it somewhere cheaper, keep
it for an audit or check what is in it. Removing old data stops being a decision you cannot take
back in the middle of a busy afternoon.

## Detaching without blocking, and the default partition

A plain `DETACH PARTITION` takes a strong lock on the parent, so every query on `events_by_month`
waits for it, briefly but every time. `DETACH PARTITION … CONCURRENTLY` does the same work in two
steps that let queries go on, at the price of not being allowed inside a transaction block:

```
market=# ALTER TABLE events_by_month DETACH PARTITION events_2026_02 CONCURRENTLY;
ALTER TABLE
Time: 4.019 ms
```

It worked for February. Now give the table a **default partition**, a partition with no interval
that takes every row no other partition accepts, and try the same on January:

```
market=# CREATE TABLE events_default PARTITION OF events_by_month DEFAULT;
CREATE TABLE
Time: 7.076 ms

market=# ALTER TABLE events_by_month DETACH PARTITION events_2026_01 CONCURRENTLY;
ERROR:  cannot detach partitions concurrently when a default partition exists
Time: 1.309 ms

market=# INSERT INTO events_by_month VALUES (0, '2026-03-01', NULL, 'view', '{}');
INSERT 0 1
Time: 2.131 ms

market=# SELECT tableoid::regclass, id, at FROM events_by_month WHERE id = 0;
    tableoid    | id |           at           
----------------+----+------------------------
 events_default |  0 | 2026-03-01 00:00:00-03
(1 row)

Time: 1.542 ms
```

The default partition caught the March row that section 03 refused. It also made the concurrent
detach impossible, with an error that says so. A default partition changes how other partitions
can be added and removed. Every change to the intervals has to check that the default does not
already hold rows that would now belong elsewhere: the same full scan the `CHECK` constraint saved
above, this time of the default.

So a default partition is a trade, and the usual advice is to prefer **creating partitions ahead of
time** and to keep a default only where the alternative is worse: on a list, where an unknown value
should be stored and noticed rather than refused, and with an alert on the default holding any row
at all. A default that quietly fills with a month nobody created is the March problem, delayed and
harder to undo.
