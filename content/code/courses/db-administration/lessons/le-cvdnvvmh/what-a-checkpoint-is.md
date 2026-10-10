---
title: What a checkpoint is
version: 1
---

Lesson 7 left a debt. Every commit is safe in the log, and the table files lag behind it, so the
pages in memory that differ from their files keep piling up, and so does the log that would be
needed to rebuild them after a crash. **A checkpoint pays the debt**: it writes every dirty page to
its file, forces those files onto the disk, and then writes a record into the log saying so. From
then on, recovery never needs anything older than the point where that checkpoint started.

The process that does it is the **checkpointer**, the one that heads the list lesson 3 printed. It
starts a checkpoint every `checkpoint_timeout`, or sooner when the log has grown enough, or when
somebody asks for one with `CHECKPOINT`.

## The same row, after a checkpoint

Lesson 7 found a committed row in the log and not in the table's file. Do that again, and count
the dirty pages in memory with `pg_buffercache`, the extension lesson 6 used to look inside shared
buffers (`IF NOT EXISTS` makes the first line harmless if it is already there):

```
shop=# CREATE EXTENSION IF NOT EXISTS pg_buffercache;
CREATE EXTENSION

shop=# CREATE TABLE notes (id int PRIMARY KEY, body text);
CREATE TABLE

shop=# INSERT INTO notes VALUES (1, 'written down first');
INSERT 0 1

shop=# SELECT pg_relation_filepath('notes');
 pg_relation_filepath 
----------------------
 base/16386/16428
(1 row)

shop=# SELECT count(*) AS dirty FROM pg_buffercache WHERE isdirty;
 dirty 
-------
 15321
(1 row)
ana@db:~$ sudo grep -c 'written down first' /var/lib/postgresql/16/main/base/16386/16428
0
```

The row is not in the file, as before. **15321 pages in memory differ from their files**: on the
recording machine `shop` had just been loaded and no checkpoint had run since, and on yours the
count is whatever has changed since the last one. Now ask for a checkpoint and look again:

```
shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT count(*) AS dirty FROM pg_buffercache WHERE isdirty;
 dirty 
-------
     0
(1 row)
ana@db:~$ sudo grep -c 'written down first' /var/lib/postgresql/16/main/base/16386/16428
1
```

**No dirty page is left, and the row is in the table's file.** Nothing changed for the session
that inserted it: the commit was durable before, because of the log. What changed is that the log
written before this checkpoint is no longer needed to make it so.

## Where the server remembers it

Every checkpoint is recorded in a small file of the data directory, `global/pg_control`, which the
server reads first at every start. `pg_controldata` prints it, and like `pg_waldump` it lives with
the server's programs rather than on your `PATH`:

```
ana@db:~$ sudo /usr/lib/postgresql/16/bin/pg_controldata /var/lib/postgresql/16/main | grep -E 'state|checkpoint location|REDO'
Database cluster state:               in production
Latest checkpoint location:           0/158532B8
Latest checkpoint's REDO location:    0/15853280
Latest checkpoint's REDO WAL file:    000000010000000000000015
```

Two positions, and **the REDO location comes first**. A checkpoint notes where the log is when it
starts, which is its redo point, then writes the pages while the log goes on growing, and only at
the end writes its own record at the later position. A change made while the pages were being
written may or may not have reached its file, so recovery has to start from the redo point, not
from the record. `in production` means the server is running; after a clean stop it says `shut
down`, and that difference is the first thing the server checks when it starts.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The write-ahead log as a stream from left to right. A checkpoint starts at the redo point, writes the dirty pages while the log goes on, and ends with a checkpoint record. Segments before the redo point are no longer needed and are recycled. After a crash, start-up replays everything from the redo point to the end of the log.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"133\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"246\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"359\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"472\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"585\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"133\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no longer needed: recycled</text><text x=\"700\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper-dim)\">→</text><text x=\"20\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the write-ahead log, oldest on the left</text><line x1=\"246\" y1=\"60\" x2=\"246\" y2=\"164\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"246\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">checkpoint starts</text><text x=\"246\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">redo lsn</text><line x1=\"430\" y1=\"60\" x2=\"430\" y2=\"164\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"430\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">checkpoint record</text><text x=\"430\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">checkpoint location</text><text x=\"338.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dirty pages written to their files</text><text x=\"338.0\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">spread over the interval</text><line x1=\"640\" y1=\"60\" x2=\"640\" y2=\"164\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"5 4\"></line><text x=\"640\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">crash</text><text x=\"640\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">kill -9</text><line x1=\"246\" y1=\"210\" x2=\"636\" y2=\"210\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"443.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">at start-up, everything from the redo point is replayed</text><text x=\"430\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pg_control remembers where the last checkpoint record is, and that record names its redo point</text></svg>", "caption": "A checkpoint moves the point where recovery would start. Everything older than it can go."}
```

## The line it leaves in the log

`log_checkpoints` is on by default since PostgreSQL 15, so every checkpoint writes two lines to
the server log:

```
ana@db:~$ sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:28:02.835 -03 [102] LOG:  checkpoint starting: immediate force wait
2026-10-10 04:28:03.116 -03 [102] LOG:  checkpoint complete: wrote 15324 buffers (93.5%); 0 WAL file(s) added, 0 removed, 20 recycled; write=0.109 s, sync=0.160 s, total=0.281 s; sync files=624, longest=0.072 s, average=0.001 s; distance=331151 kB, estimate=331151 kB; lsn=0/158532B8, redo lsn=0/15853280
```

The first line says **why** it started. `immediate force wait` is the `CHECKPOINT` command: do it
now, at full speed, and make the caller wait. A routine one says `time` or `wal`, and the next
section makes both happen. The second line is the report:

| part | what it says |
| --- | --- |
| `wrote 15324 buffers (93.5%)` | pages written, and what share of shared buffers that is |
| `0 WAL file(s) added, 0 removed, 20 recycled` | what happened to the segments older than the redo point, as lesson 7 showed |
| `write=`, `sync=`, `total=` | seconds spent writing the pages, waiting for the disk to confirm them, and in all |
| `sync files=624` | how many files had to be forced to disk |
| `distance=331151 kB` | how much log was written since the previous checkpoint |
| `estimate=` | the server's running guess of that distance, which decides how many segments it recycles |
| `lsn=`, `redo lsn=` | the same two positions `pg_controldata` showed |

**`write` and `sync` are the numbers to watch.** A routine checkpoint is supposed to spread its
writing over most of the interval, so a long `write` is normal; a long `sync` means the disk took
that long to confirm what it had been given, and lesson 9 is about disks.
