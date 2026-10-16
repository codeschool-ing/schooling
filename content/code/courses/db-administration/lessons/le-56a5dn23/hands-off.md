---
title: The files nobody touches by hand
version: 1
---

Everything in the data directory can be read, and almost nothing in it may be changed by anything
but the server. The list below is short, and every item on it is somebody's bad night.

**Never delete files in `pg_wal` to free space.** It is the first thing people try when a disk fills,
because the directory is big and the names look like logs. They are not logs in the sense of
something a person reads: the server needs every segment since the last checkpoint to make the data
files consistent after a crash, and a replica or an archive may still need older ones. Delete the
wrong one and the cluster may not start again. Lesson 7 says why the directory grows, and lesson 24
writes the runbook for a full disk that does not start with `rm`.

**Never delete anything in `pg_xact`, `pg_multixact` or `global`** because it is small and its purpose
is unclear. `pg_xact` is the record of which transactions committed; without it, every row in every
table has an unknown status.

**Never copy the data directory of a running server** and call it a backup. The files change while
`cp` reads them, and the copy is a mixture of moments that no server can make sense of. A copy taken
with the server stopped is consistent; a running server is backed up with tools built for it, and
that is `db-reliability` lesson 3.

**Never delete `postmaster.pid` to make a server start.** If the server refuses because the file
exists, either it is really running — and two servers on one directory destroy it — or the old
process is gone and the server already handles that by itself. The message it prints says which.

**Never edit a file under `base/`**, and never move one. The catalogue records which file is which
table; a file moved by hand is a table the server cannot find, or worse, one it reads in the wrong
place.

**Never change ownership or permissions inside the directory.** The server refuses to start if its
data directory is open to the other accounts on the machine, and that refusal is the only thing standing
between the data and every other account on the machine.

What you may do is everything this lesson did: list it, measure it, read `PG_VERSION` and
`postmaster.pid`, and ask the server, with `pg_relation_filepath` and the size functions, which file
is what. **When you want something in the data directory to change, the request goes through the
server**: SQL, `pg_ctlcluster`, or one of the tools later lessons introduce. That is the one habit
that keeps the directory in a state the server can trust.
