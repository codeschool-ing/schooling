---
title: Both, neither, and the restart that loads the wrong file
version: 1
---

Snapshots and the log are not exclusive. **A Redis with both on writes both, and at start it loads
only one: the append-only file.** That rule is harmless while both have been on from the beginning,
and it empties a database the day somebody turns the log on for an instance that had only snapshots.

## Turning the log on the wrong way

An instance with snapshots only, two orders in it, stopped cleanly so the final snapshot holds them:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-both:/data redis:7.4
33d3f2a10206c9d73ec3d459433f178362356623dffbb87af9f522b31defae5a
ana@vm:~$ docker exec redis redis-cli SET order:1001 paid
OK
ana@vm:~$ docker exec redis redis-cli SET order:1002 paid
OK
ana@vm:~$ docker stop redis
redis
ana@vm:~$ docker rm redis
redis
```

The obvious way to add the log is to start the container again with `--appendonly yes`:

```
ana@vm:~$ docker run -d --name redis --network nosql -v redis-both:/data redis:7.4 redis-server --appendonly yes
1b648c394ceb034a868f0586267715556e13a5402b950d945fb77ed03f08a1ce
ana@vm:~$ docker exec redis redis-cli DBSIZE
0
ana@vm:~$ docker logs redis 2>&1 | grep -E "AOF|loaded"
1:C 10 Oct 2026 19:40:12.255 * Configuration loaded
1:M 10 Oct 2026 19:40:12.261 * Creating AOF base file appendonly.aof.1.base.rdb on server start
1:M 10 Oct 2026 19:40:12.264 * Creating AOF incr file appendonly.aof.1.incr.aof on server start
ana@vm:~$ docker exec redis ls -l /data
total 8
drwx------ 2 redis redis 4096 Oct 10 19:40 appendonlydir
-rw------- 1 redis redis  128 Oct 10 19:40 dump.rdb
ana@vm:~$ docker stop redis
redis
ana@vm:~$ docker run --rm -v redis-both:/data redis:7.4 ls -l /data
total 8
drwx------ 2 redis redis 4096 Oct 10 19:40 appendonlydir
-rw------- 1 redis redis   89 Oct 10 19:40 dump.rdb
```

**`DBSIZE` is 0.** At start, Redis saw that the log was on, found no log, created an empty one and
loaded it. The `dump.rdb` with the two orders, 128 bytes, was still beside it and was never read.
Then the clean stop wrote a final snapshot of what was in memory, which was nothing, over it: 89
bytes, an empty dataset. The orders were in a file on the volume until the moment somebody did the
careful thing and stopped the server properly.

## Turning it on the right way

Ask the running server to start the log. `CONFIG SET appendonly yes` makes Redis write a base file
from what is in memory now, and only then switches the log on:

```
ana@vm:~$ docker rm redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-safe:/data redis:7.4
355d804bec7924f0bae1a803c25222394ed35690d674ee573c063eee27bcbf8f
ana@vm:~$ docker exec redis redis-cli SET order:1001 paid
OK
ana@vm:~$ docker exec redis redis-cli SET order:1002 paid
OK
ana@vm:~$ docker exec redis redis-cli CONFIG SET appendonly yes
OK
ana@vm:~$ docker exec redis redis-cli INFO persistence | grep -E "^aof_(enabled|rewrite_in_progress|last_bgrewrite_status)"
aof_enabled:1
aof_rewrite_in_progress:0
aof_last_bgrewrite_status:ok
```

`aof_rewrite_in_progress:0` and `aof_last_bgrewrite_status:ok` say the base file is written. Now the
container can be started with the flag, so that it stays on:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-safe:/data redis:7.4 redis-server --appendonly yes
7dc13c8b1d98a859af3654f6adf2a050ebb34e5879c36994243c7c7b2581cace
ana@vm:~$ docker exec redis redis-cli DBSIZE
2
ana@vm:~$ docker logs redis 2>&1 | grep -E "loaded"
1:C 10 Oct 2026 19:40:16.664 * Configuration loaded
1:M 10 Oct 2026 19:40:16.672 * Done loading RDB, keys loaded: 2, keys expired: 0.
1:M 10 Oct 2026 19:40:16.672 * DB loaded from base file appendonly.aof.1.base.rdb: 0.003 seconds
1:M 10 Oct 2026 19:40:16.672 * DB loaded from append only file: 0.003 seconds
```

Both orders came back, loaded from the log's base file. **`CONFIG SET` changes only the running
process**: a container started without the flag would start without the log, and load the snapshot
again. With a configuration file instead of flags, `CONFIG REWRITE` writes the change into the file.

## Neither: Redis as a cache

A Redis that holds only copies of data kept elsewhere, such as rendered pages, has nothing to save. An
empty `save` turns snapshots off, and the log stays off:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql redis:7.4 redis-server --save "" --appendonly no
b7539768319ce3f836267b7382de19b816dd6d4e455c2eba1ae56d317c0309f2
ana@vm:~$ docker exec redis redis-cli CONFIG GET save
save

ana@vm:~$ docker exec redis redis-cli SET page:/product/KB-101 "<html>…</html>"
OK
ana@vm:~$ docker stop redis
redis
ana@vm:~$ docker start redis
redis
ana@vm:~$ docker exec redis redis-cli DBSIZE
0
```

The page was gone after a clean stop, which is the point. A restart of a pure cache starts empty and
fills again from the system behind it. It also starts at once, with no file to load; an instance that
saves would spend its forks and its disk on data nobody needs back. Lesson 14 is about the other
setting a cache needs, what to throw away when memory is full.

## When saving fails

A snapshot that cannot be written does more than log an error. A read-only volume stands in here for
the commonest real cause, a full disk:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-data:/data:ro redis:7.4
90a96891797bf0d436b0ae86971bb264ee1988bf6d949ad1445000a7a151e836
ana@vm:~$ docker exec redis redis-cli BGSAVE
Background saving started
ana@vm:~$ docker exec redis redis-cli SET order:100003 paid
MISCONF Redis is configured to save RDB snapshots, but it's currently unable to persist to disk. Commands that may modify the data set are disabled, because this instance is configured to report errors during writes if RDB snapshotting fails (stop-writes-on-bgsave-error option). Please check the Redis logs for details about the RDB error.

ana@vm:~$ docker logs redis 2>&1 | grep -E "Failed opening"
27:C 10 Oct 2026 19:40:19.356 # Failed opening the temp RDB file temp-27.rdb (in server root dir /data) for saving: Read-only file system
```

**Redis refused the write.** By default, after a snapshot fails, Redis refuses every write until one
succeeds, `stop-writes-on-bgsave-error yes`, because accepting writes it cannot save would be
promising a durability it does not have. It looks like an outage, and it is one; the cure is the
disk, not the setting. The log line names the file and the reason.

## The fields worth reading

`INFO persistence` has about thirty fields. A handful answer the questions an operator asks:

```
ana@vm:~$ docker exec redis redis-cli INFO persistence | grep -E "^(loading|rdb_changes_since_last_save|rdb_bgsave_in_progress|rdb_last_bgsave_status|aof_enabled|aof_rewrite_in_progress|aof_last_bgrewrite_status|aof_last_write_status):"
loading:0
rdb_changes_since_last_save:0
rdb_bgsave_in_progress:0
rdb_last_bgsave_status:err
aof_enabled:0
aof_rewrite_in_progress:0
aof_last_bgrewrite_status:ok
aof_last_write_status:ok
```

| field | what it tells you |
| --- | --- |
| `loading` | `1` while a restart is still reading its file; Redis answers `LOADING` errors until then |
| `rdb_changes_since_last_save` | writes a crash would lose if snapshots are all you have |
| `rdb_bgsave_in_progress` | a snapshot is being written, and the fork is using memory |
| `rdb_last_bgsave_status` | `err` here is the `MISCONF` above, before the first refused write |
| `aof_enabled` | whether the log is on in the running process, whatever the configuration file says |
| `aof_rewrite_in_progress`, `aof_last_bgrewrite_status` | a rewrite running, and whether the last one worked |
| `aof_last_write_status` | `err` means a write to the log failed, and the disk is the place to look |

**`rdb_last_bgsave_status` and `aof_last_write_status` are the two to alert on**, which is part of
lesson 20.
