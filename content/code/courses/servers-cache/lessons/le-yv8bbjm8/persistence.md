---
title: What survives a restart
version: 1
---

Memory is gone when the process stops. Redis can keep a copy on disk in two ways, and for a pure cache
it can keep none: **whether a cache survives a restart is a choice, not a given**, and it decides how
slow the first minutes after a restart are (lesson 11).

## Snapshots

The **RDB** file is a snapshot of the whole dataset at one moment. Ubuntu's configuration takes one
after an hour with any change, five minutes with a hundred, or a minute with ten thousand, and `BGSAVE`
takes one now, in a child process, without stopping the server:

```
ana@web:~$ redis-cli FLUSHALL && redis-cli CONFIG SET maxmemory 0 && redis-cli CONFIG SET maxmemory-policy noeviction
OK
OK
OK
ana@web:~$ redis-cli SET before-snapshot 1 && redis-cli BGSAVE && sleep 1 && sudo ls -l /var/lib/redis
OK
Background saving started
total 4
-rw-rw---- 1 redis redis 113 Oct  7 01:24 dump.rdb
ana@web:~$ redis-cli SET after-snapshot 2 && redis-cli DBSIZE
OK
2
ana@web:~$ redis-cli SHUTDOWN NOSAVE; sleep 1; sudo systemctl start redis-server; sleep 1; redis-cli KEYS "*"
before-snapshot
```

`SHUTDOWN NOSAVE` stops Redis the way a crash would, without the final snapshot a clean stop takes.
After the restart, **the key written before the snapshot is back and the one written after it is
lost.** A snapshot is cheap and compact, and everything since the last one is at risk.

## The append-only file

The **AOF** writes every command that changes data to a log, and on start Redis replays it. Turned on
and saved into the configuration file with `CONFIG REWRITE`, so that the setting survives the restart
too:

```
ana@web:~$ redis-cli CONFIG SET appendonly yes && redis-cli CONFIG REWRITE && sleep 2 && sudo ls /var/lib/redis /var/lib/redis/appendonlydir
OK
OK
/var/lib/redis:
appendonlydir
dump.rdb

/var/lib/redis/appendonlydir:
appendonly.aof.1.base.rdb
appendonly.aof.1.incr.aof
appendonly.aof.manifest
ana@web:~$ redis-cli SET after-aof 3 && sleep 1 && redis-cli SHUTDOWN NOSAVE; sleep 1; sudo systemctl start redis-server; sleep 1; redis-cli KEYS "*" | sort
OK
after-aof
before-snapshot
```

**The key written one second before the crash survived.** With Ubuntu's default `appendfsync
everysec`, the log is flushed to disk once a second, so at most about a second of writes is at risk, at
the cost of a disk write every second. Since version 7, the AOF is a directory: a base snapshot, an
incremental log and a manifest that says which files make up the current state.

| | RDB snapshots | AOF | neither |
|---|---|---|---|
| lost in a crash | everything since the last snapshot | about a second | everything |
| restart | fast: load one file | slower: replay the log | instant, and empty |
| for | a cache that should start warm | data that must not be lost | a cache that can start cold |

For a cache, the honest question is **what a cold start costs**. If the application can rebuild every
value from its database and the database can take the load, `save ""` and no AOF are the simplest
setting. If a cold cache would send the database a stampede, keep the snapshots, and read lesson 11.
