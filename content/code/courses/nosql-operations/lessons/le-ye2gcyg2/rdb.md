---
title: Snapshots, and what a crash takes with it
version: 1
---

Redis keeps everything in memory, and memory is gone when the process stops. **Persistence is how
much of it Redis writes somewhere that survives**, and Redis offers two ways that differ in what a
crash costs. The first is a snapshot: every so often, the whole dataset is written to one file,
`dump.rdb`. Whatever was written after the last snapshot exists only in memory.

The wrong picture is that Redis "saves to disk" the way a relational database does, every committed
write on disk before the client hears `OK`. With snapshots it does not, and this section shows the
gap by killing the server on purpose.

## A container whose files outlive it

Lesson 12 used a container with nothing worth keeping. Here the data directory, `/data` in the
official image, goes on a **named volume**, so it survives the container being removed:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql -v redis-data:/data redis:7.4
5122ba40164c08121fb0571e80e3188ef11b545d67639c53f7ebe822ef13f320
```

`-v redis-data:/data` creates the volume on first use. Every container in this lesson uses one, and
each section names its own, so they never mix.

## When a snapshot is taken

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET save
1) "save"
2) "3600 1 300 100 60 10000"
127.0.0.1:6379> CONFIG GET dir
1) "dir"
2) "/data"
127.0.0.1:6379> EVAL "for i = 1, 100000 do redis.call('SET', 'order:' .. i, 'paid') end return redis.call('DBSIZE')" 0
(integer) 100000
127.0.0.1:6379> BGSAVE
Background saving started
127.0.0.1:6379> LASTSAVE
(integer) 1791661190
127.0.0.1:6379> SET order:100001 paid
OK
127.0.0.1:6379> SET order:100002 paid
OK
```

`save` holds the rules for automatic snapshots as pairs of numbers: `3600 1 300 100 60 10000` means
"after 3,600 seconds if at least 1 key changed, after 300 seconds if at least 100 changed, after 60
seconds if at least 10,000 changed". These are Redis's defaults, and the official image starts with
them. `dir` is where the file goes.

The `EVAL` wrote 100,000 orders in one Lua loop, the quickest way to have a dataset worth saving.
`BGSAVE` asked for a snapshot now, in the background; `LASTSAVE` answers when the last one finished,
as a Unix time. Then two more orders arrived. What Redis knows about them:

```
ana@vm:~$ docker exec redis redis-cli INFO persistence | grep -E "^rdb_(changes_since_last_save|last_bgsave_status|last_cow_size)"
rdb_changes_since_last_save:2
rdb_last_bgsave_status:ok
rdb_last_cow_size:339968
ana@vm:~$ docker exec redis ls -l /data
total 1748
-rw------- 1 redis redis 1788993 Oct 10 19:39 dump.rdb
```

**`rdb_changes_since_last_save` is the number of writes a crash would lose right now**: the two
orders written after the snapshot. The file in the volume holds the other 100,000.

## The crash

`docker kill` sends `SIGKILL`, which ends the process with no chance to do anything first: the
closest a container gets to a server losing power, though the machine's own memory and disk carry
on.

```
ana@vm:~$ docker kill redis
redis
ana@vm:~$ docker start redis
redis
ana@vm:~$ docker exec redis redis-cli DBSIZE
100000
ana@vm:~$ docker exec redis redis-cli EXISTS order:100001 order:100002
0
ana@vm:~$ docker logs redis 2>&1 | grep -E "RDB|loaded"
28:C 10 Oct 2026 19:39:50.339 * Fork CoW for RDB: current 0 MB, peak 0 MB, average 0 MB
1:M 10 Oct 2026 19:39:52.924 * Loading RDB produced by version 7.4.11
1:M 10 Oct 2026 19:39:52.924 * RDB age 2 seconds
1:M 10 Oct 2026 19:39:52.924 * RDB memory usage when created 8.23 Mb
1:M 10 Oct 2026 19:39:52.995 * Done loading RDB, keys loaded: 100000, keys expired: 0.
1:M 10 Oct 2026 19:39:52.995 * DB loaded from disk: 0.072 seconds
```

**100,000 keys came back and orders 100001 and 100002 did not.** Both had been acknowledged with
`OK`; neither was in the snapshot. The log says where the data came from: an RDB file, produced by
7.4.11, two seconds old when it was loaded.

## A clean stop is not the test

The same experiment with `docker stop`, which sends `SIGTERM` and waits:

```
ana@vm:~$ docker exec redis redis-cli SET order:100001 paid
OK
ana@vm:~$ docker stop redis
redis
ana@vm:~$ docker start redis
redis
ana@vm:~$ docker exec redis redis-cli DBSIZE
100001
ana@vm:~$ docker logs redis 2>&1 | grep -E "shutdown|final RDB"
1:signal-handler (1791661193) Received SIGTERM scheduling shutdown...
1:M 10 Oct 2026 19:39:53.402 * User requested shutdown...
1:M 10 Oct 2026 19:39:53.402 * Saving the final RDB snapshot before exiting.
```

Nothing was lost, because Redis heard the signal, wrote a final snapshot and only then exited. That
is the case that makes snapshots look safe: every restart anybody does on purpose is a clean one.
**A crash, an out-of-memory kill or a machine that loses power gives no such warning**, and those
are the restarts persistence exists for. Test with `docker kill`, never with `docker stop`.

## What a snapshot costs

`BGSAVE` forks the Redis process. The child writes the file from a frozen copy of memory while the
parent keeps serving clients, and the operating system shares the two copies until the parent
changes a page, which it then has to copy. On an instance that is busy writing, a snapshot can
briefly need much more memory than the dataset, and `rdb_last_cow_size` in `INFO persistence` says
how much was copied the last time. A snapshot of a few gigabytes also takes seconds to write, so
snapshots are taken minutes apart, and minutes of writes is what they risk.
