---
title: The append-only file
version: 1
---

The other way is a log. **With the append-only file on, every write command is appended to a file
as it is executed**, and a restart replays the file to rebuild memory. The question is no longer
"when was the last snapshot" but "how far did the operating system get in writing the log to the
disk", and Redis lets you choose that with one setting.

## The same crash, with the log on

A new container on a new volume, with `--appendonly yes` added after the image name. Everything
after the image is passed to `redis-server` as configuration:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-aof:/data redis:7.4 redis-server --appendonly yes
b3b2813b5dd4836267c387ac61ea284aaa8b670a5b9dba7fa5e8f4607b571e43
```

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET appendonly
1) "appendonly"
2) "yes"
127.0.0.1:6379> CONFIG GET appendfsync
1) "appendfsync"
2) "everysec"
127.0.0.1:6379> SET order:1001 paid
OK
127.0.0.1:6379> SET order:1002 paid
OK
127.0.0.1:6379> INCR stock:KB-101
(integer) 1
```

`appendfsync` is `everysec`, the default: Redis writes each command to the file at once and asks the
operating system to flush the file to the disk once a second. Now the same `docker kill`:

```
ana@vm:~$ docker kill redis
redis
ana@vm:~$ docker start redis
redis
ana@vm:~$ docker exec redis redis-cli DBSIZE
3
ana@vm:~$ docker logs redis 2>&1 | grep -E "loaded"
1:C 10 Oct 2026 19:39:54.517 * Configuration loaded
1:C 10 Oct 2026 19:39:55.152 * Configuration loaded
1:M 10 Oct 2026 19:39:55.157 * Done loading RDB, keys loaded: 0, keys expired: 0.
1:M 10 Oct 2026 19:39:55.157 * DB loaded from base file appendonly.aof.1.base.rdb: 0.001 seconds
1:M 10 Oct 2026 19:39:55.157 * DB loaded from incr file appendonly.aof.1.incr.aof: 0.000 seconds
1:M 10 Oct 2026 19:39:55.157 * DB loaded from append only file: 0.001 seconds
```

**All three keys survived a kill that gave Redis no warning.** The log shows the replay: a base file
first, then an incremental file on top of it. Those are two of the three files the append-only file
is made of since Redis 7.

## Three files, not one

```
ana@vm:~$ docker exec redis ls -l /data/appendonlydir
total 12
-rw------- 1 redis redis  89 Oct 10 19:39 appendonly.aof.1.base.rdb
-rw------- 1 redis redis 136 Oct 10 19:39 appendonly.aof.1.incr.aof
-rw------- 1 redis redis  88 Oct 10 19:39 appendonly.aof.manifest
ana@vm:~$ docker exec redis cat /data/appendonlydir/appendonly.aof.manifest
file appendonly.aof.1.base.rdb seq 1 type b
file appendonly.aof.1.incr.aof seq 1 type i
ana@vm:~$ docker exec redis cat /data/appendonlydir/appendonly.aof.1.incr.aof
*2
$6
SELECT
$1
0
*3
$3
SET
$10
order:1001
$4
paid
*3
$3
SET
$10
order:1002
$4
paid
*2
$4
INCR
$12
stock:KB-101
```

The **manifest** lists the files and their order. The **base** is a snapshot of the dataset at the
moment the log was started, in RDB format, which is why it ends in `.rdb`; it is nearly empty here,
because the log was started with an empty dataset. The **incremental** file holds every write since,
in the same protocol a client uses to talk to Redis: `*3` is a command of three parts, `$10` a string
of 10 bytes. You can read it, and in an emergency you can edit it: a `FLUSHALL` somebody typed by
mistake is the last command in this file, and removing it before a restart, and before the next rewrite, brings the data back.

## Why the log has to be rewritten

A log of commands grows with every command, even when the data does not. Ten thousand increments of
one counter:

```
ana@vm:~$ docker exec redis redis-cli EVAL "for i = 1, 10000 do redis.call('INCR', 'stock:KB-101') end" 0

ana@vm:~$ docker exec redis ls -l /data/appendonlydir
total 332
-rw------- 1 redis redis     89 Oct 10 19:39 appendonly.aof.1.base.rdb
-rw------- 1 redis redis 330188 Oct 10 19:39 appendonly.aof.1.incr.aof
-rw------- 1 redis redis     88 Oct 10 19:39 appendonly.aof.manifest
```

One key with one number in it, and the incremental file went from 136 bytes to 330,188, because it
holds ten thousand `INCR` commands. Replaying them on a restart gives the right answer slowly.
`BGREWRITEAOF` writes a fresh base from what is in memory, starts a new, empty incremental file and
deletes the old pair:

```
ana@vm:~$ docker exec redis redis-cli BGREWRITEAOF
Background append only file rewriting started
ana@vm:~$ docker exec redis ls -l /data/appendonlydir
total 8
-rw------- 1 redis redis 145 Oct 10 19:39 appendonly.aof.2.base.rdb
-rw------- 1 redis redis   0 Oct 10 19:39 appendonly.aof.2.incr.aof
-rw------- 1 redis redis  88 Oct 10 19:39 appendonly.aof.manifest
ana@vm:~$ docker exec redis cat /data/appendonlydir/appendonly.aof.manifest
file appendonly.aof.2.base.rdb seq 2 type b
file appendonly.aof.2.incr.aof seq 2 type i
ana@vm:~$ docker exec redis redis-cli GET stock:KB-101
10001
```

**The sequence number went from 1 to 2**, the base now holds the counter's value, 10001, and the
increments are gone because the value already includes them. Redis rewrites the log by itself when
it has doubled since the last rewrite and is at least 64 MB, the defaults of
`auto-aof-rewrite-percentage` and `auto-aof-rewrite-min-size`. A rewrite forks, like a snapshot,
and costs memory the same way.
