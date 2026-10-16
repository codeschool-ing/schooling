---
title: A limit, and what Redis does when it reaches it
version: 1
---

Everything Redis holds is in memory, so the size of the machine is the size of the database. **Left
alone, Redis has no limit at all**: it grows until the operating system runs out and kills the
largest process on the machine, which is Redis. `maxmemory` sets a ceiling inside the process, and
`maxmemory-policy` decides what happens at the ceiling. That second setting is where Redis is told
whether it is a cache or a database, and it is the subject of this lesson.

If you took `servers-cache`, lesson 8 there met eviction in front of a web server. This lesson runs
every policy against the same load and then looks at the instance that is a cache and a database at
once, which is where operations go wrong.

## The container

This lesson needs one `redis` container, and it is clearer from empty:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql redis:7.4
2d36ee12e6bf1e129db6ac1ca589bc70167356649d65961c16dcdb9998b823c5
```

## Ceiling and policy

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET maxmemory
1) "maxmemory"
2) "0"
127.0.0.1:6379> CONFIG GET maxmemory-policy
1) "maxmemory-policy"
2) "noeviction"
127.0.0.1:6379> CONFIG SET maxmemory 4mb
OK
```

`0` means no limit, which is the default on a 64-bit machine, and the default policy is `noeviction`.
4 MB is absurdly small on purpose, so that the ceiling is reached in a second.

## Filling it under `noeviction`

The shell writes 20,000 `SET` commands, each a page of 100 bytes, and pipes them into one
`redis-cli`, which sends them in turn. `grep . | sort | uniq -c` counts the answers:

```
ana@vm:~$ seq 1 20000 | awk '{ printf "SET page:%d %0100d\n", $1, 0 }' | docker exec -i redis redis-cli | grep . | sort | uniq -c
  17668 OK
   2332 OOM command not allowed when used memory > 'maxmemory'.
```

**17,668 pages were stored and 2,332 were refused** with `OOM command not allowed when used memory
> 'maxmemory'`. Nothing was deleted to make room: under `noeviction`, Redis refuses every command that
could add data once it is at the ceiling. What it still allows:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET product:KB-101 34990
(error) OOM command not allowed when used memory > 'maxmemory'.
127.0.0.1:6379> GET page:1
"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
127.0.0.1:6379> DEL page:1
(integer) 1
ana@vm:~$ docker exec redis redis-cli INFO memory | grep -E "^(used_memory_human|maxmemory_human|maxmemory_policy):"
used_memory_human:4.06M
maxmemory_human:4.00M
maxmemory_policy:noeviction
```

A write of anything new is refused, a product included; a read works; a `DEL` works, because it
frees memory. Used memory sits just over the ceiling, which is how Redis decides a command is over it.

**This is the right behaviour for a database.** The application gets an error it can see, page
somebody, and nothing it stored has quietly gone. For a cache it is the wrong behaviour, because a
cache that refuses new entries when full stops caching exactly when it is busiest.

## The ceiling inside the container's ceiling

`maxmemory` counts the data Redis stores, not everything the process uses. Buffers for clients and
replicas, and the copy a fork makes while saving (lesson 13), are on top. If the container also has a memory limit, `docker run --memory`, set `maxmemory` well below it.
Otherwise the kernel kills the container before Redis ever reaches its own ceiling, and that is the out-of-memory exit 137 of lesson
1 rather than an error a client can read.
