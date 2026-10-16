---
title: Where the files live
version: 1
---

Lesson 3 asked the server where its data is, and it said `/var/lib/postgresql/16/main`. That
directory is the **cluster**: every database, every table and every index the server holds is a file
somewhere under it, and nothing the server needs to start lives anywhere else except its
configuration. Only the `postgres` user can open it, so look with `sudo`:

```
ana@db:~$ sudo ls -l /var/lib/postgresql/16/main
total 84
-rw------- 1 postgres postgres    3 Oct 10 03:18 PG_VERSION
drwx------ 8 postgres postgres 4096 Oct 10 04:11 base
drwx------ 2 postgres postgres 4096 Oct 10 04:11 global
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_commit_ts
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_dynshmem
drwx------ 4 postgres postgres 4096 Oct 10 03:18 pg_logical
drwx------ 4 postgres postgres 4096 Oct 10 03:18 pg_multixact
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_notify
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_replslot
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_serial
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_snapshots
drwx------ 2 postgres postgres 4096 Oct 10 04:11 pg_stat
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_stat_tmp
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_subtrans
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_tblspc
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_twophase
drwx------ 3 postgres postgres 4096 Oct 10 04:11 pg_wal
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_xact
-rw------- 1 postgres postgres   88 Oct 10 03:18 postgresql.auto.conf
-rw------- 1 postgres postgres  130 Oct 10 04:11 postmaster.opts
-rw------- 1 postgres postgres  107 Oct 10 04:11 postmaster.pid
```

Most of those names are internal bookkeeping you will never open, and the server would be right to
object if you did. Five are worth knowing by name:

| entry | what it holds |
|---|---|
| `base/` | **the databases**: one subdirectory per database, and inside it one or more files per table and index |
| `global/` | the few tables every database shares, such as the list of roles and the list of databases |
| `pg_wal/` | the **write-ahead log**, every change written down before it reaches a table; lessons 7 and 8 |
| `pg_xact/` | one pair of bits per transaction saying whether it committed — tiny, and without it nothing in `base/` can be read correctly |
| `PG_VERSION` | the major version that made this directory: `16`. A server of another major version refuses to start on it |

`postmaster.pid` exists only while the server runs. It is how a second server is stopped from
starting on the same directory, and how tools find the running one:

```
ana@db:~$ sudo cat /var/lib/postgresql/16/main/postmaster.pid
101
/var/lib/postgresql/16/main
1791616272
5432
/var/run/postgresql
localhost
   860661         0
ready   
```

The first line is the postmaster's process id, then the data directory, the start time in seconds
since 1970, the port, where the socket is, and what it listens on. **A server killed hard leaves this
file behind**, and the next start checks whether that process is still alive before believing it.

## How much each part weighs

```
ana@db:~$ sudo du -h -d1 /var/lib/postgresql/16/main | sort -h
4.0K	/var/lib/postgresql/16/main/pg_commit_ts
4.0K	/var/lib/postgresql/16/main/pg_dynshmem
4.0K	/var/lib/postgresql/16/main/pg_notify
4.0K	/var/lib/postgresql/16/main/pg_replslot
4.0K	/var/lib/postgresql/16/main/pg_serial
4.0K	/var/lib/postgresql/16/main/pg_snapshots
4.0K	/var/lib/postgresql/16/main/pg_stat
4.0K	/var/lib/postgresql/16/main/pg_stat_tmp
4.0K	/var/lib/postgresql/16/main/pg_tblspc
4.0K	/var/lib/postgresql/16/main/pg_twophase
12K	/var/lib/postgresql/16/main/pg_subtrans
12K	/var/lib/postgresql/16/main/pg_xact
16K	/var/lib/postgresql/16/main/pg_logical
28K	/var/lib/postgresql/16/main/pg_multixact
600K	/var/lib/postgresql/16/main/global
153M	/var/lib/postgresql/16/main/base
337M	/var/lib/postgresql/16/main/pg_wal
490M	/var/lib/postgresql/16/main
```

Two lines carry nearly everything: `base` at 153M, which is `shop` and the small databases
beside it, and **`pg_wal` at 337M — more than the data itself**. Loading a million rows in
a few big statements writes all of them to the log first, and the server keeps the log segments
around until it has reason to recycle them. That is normal, it is bounded, and lesson 7 says by what.
On your machine the second number may differ; the first should not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The data directory /var/lib/postgresql/16/main holds base, with one directory per database named by its oid; inside base/16386, the shop database, the orders table is the file 16398 with its free space map 16398_fsm and visibility map 16398_vm. Beside base are global, pg_wal and pg_xact. Ubuntu keeps the configuration in /etc/postgresql/16/main and the log in /var/log/postgresql, outside the data directory.\"><rect x=\"10\" y=\"10\" width=\"470\" height=\"300\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">/var/lib/postgresql/16/main</text><text x=\"24\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the data directory: one cluster</text><rect x=\"24\" y=\"62\" width=\"442\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"38\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">base/</text><text x=\"90\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one directory per database, named by its oid</text><rect x=\"38\" y=\"94\" width=\"414\" height=\"108\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">16386/</text><text x=\"112\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shop</text><text x=\"52\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders: one file per fork</text><rect x=\"52\" y=\"144\" width=\"126\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">16398</text><text x=\"115\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the rows</text><rect x=\"186\" y=\"144\" width=\"126\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"249\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">16398_fsm</text><text x=\"249\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">free space map</text><rect x=\"320\" y=\"144\" width=\"126\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"383\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">16398_vm</text><text x=\"383\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">visibility map</text><text x=\"38\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">global/</text><text x=\"112\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tables shared by every database: roles, the list of databases</text><text x=\"38\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">pg_wal/</text><text x=\"112\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the write-ahead log (lesson 7)</text><text x=\"38\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">pg_xact/</text><text x=\"112\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">whether each transaction committed</text><rect x=\"496\" y=\"10\" width=\"214\" height=\"300\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"603\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">kept elsewhere by Ubuntu</text><rect x=\"510\" y=\"62\" width=\"186\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"603\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/postgresql/16/main</text><text x=\"603\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">configuration (lesson 5)</text><rect x=\"510\" y=\"150\" width=\"186\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"603\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/var/log/postgresql</text><text x=\"603\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the log (lesson 19)</text></svg>", "caption": "One cluster is one directory. A table is a few files inside it, named by numbers rather than by the table's name."}
```

The figure shows the rest of this lesson in one picture: inside `base/`, a directory for `shop`,
and inside that, the files that are the `orders` table. The two boxes on the right are not in the
data directory at all, and the section after next explains why.
