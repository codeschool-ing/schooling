---
title: Two ways to give the space back, and the lock each takes
version: 1
---

Getting the space back means writing the live rows into a new, compact file and throwing the old
one away. Both tools here do that. **The difference is who can use the table while it happens.**

## VACUUM FULL

`VACUUM FULL` copies the live rows into a new file, rebuilds every index on it and swaps the files.
It is part of PostgreSQL and needs nothing installed. It holds an `ACCESS EXCLUSIVE` lock on the
table from start to finish, and that lock conflicts with everything, a plain `SELECT` included.

Three terminals show it. The first runs the rebuild:

<<<vacuum-full>>>

While it ran, a second terminal tried to count the rows:

<<<vacuum-full-select>>>

A count that normally takes a fraction of a second waited until the rebuild finished. A third
terminal, looking at `pg_locks` in the middle of it, saw why:

<<<vacuum-full-locks>>>

**`granted` is the column to read.** The `VACUUM FULL` holds `AccessExclusiveLock`, granted; the
`SELECT` asked for `AccessShareLock`, the weakest lock there is, and has not got it. The
`ShareLock` beside it belongs to the index builds inside the rebuild. On an application, every
query that touches the table stacks up behind the first one exactly like that count, for as long as
the rebuild takes. On the copy that was seconds. On a table of 200 GB it is long enough to be an
outage.

<<<vacuum-full-after>>>

The table went from 117 MB to 59 MB and the indexes from 75 MB to 34 MB. That is the whole of the
bloat, returned to the operating system. **Expect to need room for both copies while it runs**: the
new files are written before the old ones are removed, so a disk that is full because of bloat may
not have the space to fix it this way.

## pg_repack

`pg_repack` is an extension and a command-line program, maintained outside PostgreSQL and packaged
by Ubuntu per major version. It does the same rewrite and **holds the exclusive lock only for a
moment at the start and at the end**. In between it copies the rows into a new table while a
trigger records every change the application makes, then replays those changes before the swap.

Bloat the copy again the same way, then install it. The package comes from Ubuntu's archive and the
extension goes into the database that holds the table:

<<<repack 1-3>>>

```sh
sudo apt install -y postgresql-16-repack
```

<<<repack 4-5>>>

While it copied, the third terminal looked at the locks again, and then changed a row:

<<<repack-locks>>>

`pg_repack` holds `AccessShareLock`, the same lock a `SELECT` takes, so reads and writes carry on.
The `SIReadLock` is there because it copies at the `SERIALIZABLE` isolation level, to get a
consistent snapshot. **The `UPDATE` went straight through** and the trigger carried it into the new
table. The result is the same as `VACUUM FULL`'s:

<<<repack-after>>>

Three conditions come with it. **The table needs a primary key** or a unique index on columns that
are not null, because the replay finds rows by it; `pg_repack` refuses a table without one. It
needs the same spare room as `VACUUM FULL`, for the same reason. And the brief exclusive locks at
each end still have to be granted, so a long transaction holding the table makes `pg_repack` wait at
the swap, and every query arriving after it waits too. By default it waits 60 seconds and then
cancels the queries in its way; `--no-kill-backend` makes it give up instead. Lesson 22 shows that
queue in detail.

The extension in the database must match the program's version. After an upgrade of the package,
`DROP EXTENSION pg_repack; CREATE EXTENSION pg_repack;` brings them back in line, and lesson 20
meets the extension again on the way to a new major version.
