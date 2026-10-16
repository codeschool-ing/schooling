---
title: What depends on the log
version: 1
---

It is easy to file the WAL away as a safety net for crashes, a scratch area the server needs and
you do not. **The log is the one complete record of every change the cluster has made**, in order,
and three other things a DBA answers for are built by reading it again somewhere else.

| reader | what it does with the log | where it is taught |
| --- | --- | --- |
| crash recovery | replays the records written since the last checkpoint, on the same server, at start-up | lesson 8 |
| a replica | receives the records as they are written and replays them for ever, staying a copy of the primary | db-reliability lessons 11 to 13 |
| archiving and point-in-time recovery | keeps a copy of every finished segment, so that a backup plus the segments after it can be replayed to any chosen moment | db-reliability lessons 1 to 10 |
| logical decoding | turns the records back into row changes (this row inserted, that one updated) for logical replication and change-data tools | db-reliability lesson 14 |

They are one mechanism used four ways. **A replica is a server in permanent crash recovery**,
replaying a log that keeps arriving. A restore to last Tuesday at 14:05 is crash recovery that
starts from an older copy of the files and stops at a chosen record. Understanding the first
case, which lesson 8 does by causing it, is most of the way to understanding the other three.

## How much the log records

What the records carry is chosen by one setting, `wal_level`, and two others say whether anything
is reading them:

```
shop=# SELECT name, setting FROM pg_settings
shop-#  WHERE name IN ('wal_level', 'archive_mode', 'max_wal_senders');
      name       | setting 
-----------------+---------
 archive_mode    | off
 max_wal_senders | 10
 wal_level       | replica
(3 rows)
```

`wal_level` has three values. `replica`, the default, records enough for crash recovery, replicas
and archives. `logical` adds what decoding needs to rebuild rows, at the cost of somewhat more log.
`minimal` records only what crash recovery needs, which lets a few bulk operations skip the log
altogether, and in exchange no replica and no archive can be built from it. **Changing
`wal_level` needs a restart**, so it is chosen when a server is built rather than on the day a
replica is wanted, and the default is the right place to start.

`archive_mode` is `off`: no segment is being copied anywhere, so this server has no point-in-time
recovery yet. `max_wal_senders` is how many replicas or backup tools may stream the log at once,
and 10 is room nobody is using.

## The one thing never to do

When a disk fills, `pg_wal` is often the largest directory on it, full of files with meaningless
names, and deleting the oldest of them looks like a way out. **Never delete anything in `pg_wal` by
hand.** Those records are the only copy of changes that may not have reached the table files yet,
and the server reads them at its next start. Remove the wrong one and a cluster that would have
recovered by itself will refuse to start, or start with data that is silently inconsistent.

The server removes segments itself when nothing needs them any more. The next section is about
when that happens, and what can stop it.
