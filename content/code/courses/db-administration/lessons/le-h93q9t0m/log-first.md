---
title: Write it down first
version: 1
---

The obvious picture of a commit is that your row goes into the table's file and then `COMMIT`
returns. **A commit does not write your row into the table's file.** It changes a copy of the
table's page in shared memory, writes a description of the change into the **write-ahead log**,
and makes sure that description has reached the disk. Only then does `COMMIT` return. The table
file is brought up to date later, by a process that has nothing to do with your session.

That is the whole rule, and the name says it: the log is written *ahead* of the data. **No change
reaches a table file before its description has reached the log.** Everything else in this lesson
and the next follows from that sentence. The log is called WAL for short, and its files live in
`pg_wal`, the directory lesson 4 found taking more room than the data.

Why go the long way round? Because the two writes have different shapes. A row change touches one
8 kB page somewhere in a file of thousands, and a transaction that updates ten rows can touch ten
pages in ten places. Forcing all of those to disk at every commit means waiting for scattered
writes. The log is appended at its end, so a commit waits for one sequential write of a few dozen
bytes instead. If the server dies before the pages are written, **the log holds enough to make
every one of those changes again**. Lesson 8 kills the server to watch that happen.

## Your row, before it is in the table

You can see the rule with nothing but `grep`. Make a small table in `shop` and put one row in it:

```
shop=# CREATE TABLE notes (id int PRIMARY KEY, body text);
CREATE TABLE

shop=# INSERT INTO notes VALUES (1, 'written down first');
INSERT 0 1

shop=# SELECT pg_relation_filepath('notes');
 pg_relation_filepath 
----------------------
 base/16386/16420
(1 row)
```

`pg_relation_filepath` names the table's file under the data directory, as lesson 4 showed. The
row has committed. Search that file for its text, and then search the log's directory for the same
text:

```
ana@db:~$ sudo grep -c 'written down first' /var/lib/postgresql/16/main/base/16386/16420
0
ana@db:~$ sudo grep -rl 'written down first' /var/lib/postgresql/16/main/pg_wal
/var/lib/postgresql/16/main/pg_wal/000000010000000000000015
```

**The table's file does not contain the row**, and one of the files in `pg_wal` does. `grep -c`
counted no matches in the first; `grep -rl` named the file it found in the second. The commit was
acknowledged with the row in memory and in the log, and nowhere else. The numbers in the path may
differ on your machine: ask `pg_relation_filepath` and use what it answers.

The page is still in memory, marked **dirty**: changed since it was read, and not yet written back.
It reaches the file at the next checkpoint, or sooner if its slot in memory is needed for another
page. Lesson 8 is about the checkpoint, and it runs this same `grep` after one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"A commit changes the table page in shared memory and writes a record describing the change into the WAL buffers. At COMMIT the WAL is flushed to pg_wal on disk before the answer returns; the table page reaches the table file later, at a checkpoint.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">shared memory</text><rect x=\"10\" y=\"180\" width=\"700\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"24\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">disk</text><rect x=\"30\" y=\"50\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">INSERT … ; COMMIT</text><text x=\"105\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">your session</text><rect x=\"270\" y=\"50\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the table’s page</text><text x=\"355\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">changed, not written: dirty</text><rect x=\"530\" y=\"50\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WAL buffers</text><text x=\"610\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a record describing it</text><rect x=\"270\" y=\"215\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">base/16386/16420</text><text x=\"355\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the table’s file</text><rect x=\"530\" y=\"215\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">pg_wal/</text><text x=\"610\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the log, appended at its end</text><line x1=\"180\" y1=\"75\" x2=\"266\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"223\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"bold\">1</text><line x1=\"440\" y1=\"75\" x2=\"526\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"483\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"bold\">2</text><line x1=\"610\" y1=\"120\" x2=\"610\" y2=\"211\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"598\" y=\"148\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">3 flushed at COMMIT,</text><text x=\"598\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">before the answer</text><line x1=\"355\" y1=\"120\" x2=\"355\" y2=\"211\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#arr)\"></line><text x=\"367\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 written later,</text><text x=\"367\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">by a checkpoint (lesson 8)</text></svg>", "caption": "Two copies of one change. Only the one in the log has to be on disk before COMMIT returns."}
```

## Who writes the log

Two kinds of process write WAL to disk, and neither of them writes table pages.

**The session that commits flushes the log itself** when its records are not on disk yet, and that
flush is the wait inside `COMMIT`. The **walwriter**, one of the background processes lesson 3
listed, wakes every `wal_writer_delay` — 200 ms unless somebody changed it — and flushes whatever
has gathered in the WAL buffers. That background flush is what makes `synchronous_commit = off`
possible, and lesson 8 measures what it buys and what it risks.

Table pages are written by two other processes from the same list: the **checkpointer**, which is
lesson 8's subject, and the **background writer**, which writes a few dirty pages ahead of the
moment their memory is needed. The order between the two worlds is enforced by the server: before
any dirty page is written, the log is flushed at least as far as the last record that changed it.
