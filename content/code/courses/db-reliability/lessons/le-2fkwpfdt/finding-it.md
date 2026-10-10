---
title: Finding the moment in the log
version: 1
---

"About four in the afternoon" is not a recovery target. The log knows exactly when the mistake
committed, and which transaction it was, because it recorded every row the `DELETE` removed.
`pg_waldump` prints a segment as one line per record:

```
ana@vm:~$ sudo /usr/lib/postgresql/16/bin/pg_waldump --path=/var/lib/postgresql/16/main/pg_wal 000000010000000000000004 | awk '/desc: DELETE/ {print $8}' | sort | uniq -c
pg_waldump: error: error in WAL record at 0/4165E00: invalid record length at 0/4165EF0: expected at least 24, got 0
  12059 742,
```

Each line of the dump that describes a deleted row carries the id of the transaction that deleted
it; `awk` picked that field, and `sort | uniq -c` counted rows per transaction. **One transaction,
742, deleted 12059 rows**, the number the `DELETE` reported. Nothing else in the segment deleted
anything.

The error line on top is not a problem. `pg_waldump` read up to where the server has written so
far, found the rest of the 16 MB file still empty, and said so; `2>/dev/null` hides it from here on.

Now the commits, which carry their times:

```
ana@vm:~$ sudo /usr/lib/postgresql/16/bin/pg_waldump --path=/var/lib/postgresql/16/main/pg_wal 000000010000000000000004 2>/dev/null | grep 'desc: COMMIT' | sed -E 's/.*tx: +([0-9]+),.*COMMIT ([^;]*).*/\1  \2/'
737  2026-10-10 16:36:03.338688 -03
738  2026-10-10 16:36:04.396113 -03
739  2026-10-10 16:36:05.436931 -03
740  2026-10-10 16:36:06.476241 -03
741  2026-10-10 16:36:07.514400 -03
742  2026-10-10 16:36:08.563344 -03
743  2026-10-10 16:36:08.600046 -03
744  2026-10-10 16:36:09.641449 -03
745  2026-10-10 16:36:10.677774 -03
```

The story of the day, in transaction ids. 737 to 741 are the five orders, a second apart. **742
committed at 16:36:08.563**, and 743 to 745 are the three orders after it. Now the target can be
named exactly: everything up to, and **not including**, transaction 742.

A real segment holds far more than this one, and the `DELETE` is not always the only transaction
with thousands of rows in it. What makes this work in practice is what you already know: roughly
when, which table, and roughly how many rows. `pg_waldump` can be pointed at one table, with
`--relation`, and at a range of the log, with `--start` and `--end`, and those narrow a busy segment
to a handful of candidates. For a mistake older than the segments still on the server, the archived
ones are fetched with `pgbackrest archive-get`, and the same commands work on them.
