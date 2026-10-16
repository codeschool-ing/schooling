---
title: Holding a seat in Redis
version: 1
---

The first access pattern of section 03 was holding a seat for ten minutes while the buyer pays. In
PostgreSQL it would be a row with an expiry time, a query to skip expired holds, and a job to
delete them, all on the database that is already the box office's bottleneck. In a key-value store
it is one command.

Redis runs in a container of its own, apart from the box office. `redis-cli`, its client, is inside
the image, so every command goes through `docker exec`:

```
ana@lab:~/tickets$ docker run -d --name kv redis:7.4.11
7c8b67f5a3c9ce770a8ad4d1cd6676a78b2cdd2f6fffda28cca66735f703611f
ana@lab:~/tickets$ docker exec kv redis-cli PING
PONG
```

## One command, set only if absent

Ana starts paying for seat 42 of show 1. The key names the seat; the value names the buyer:

```
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw SET hold:show:1:seat:42 ana NX EX 600
OK
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw SET hold:show:1:seat:42 bia NX EX 600
(nil)
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw GET hold:show:1:seat:42
"ana"
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw TTL hold:show:1:seat:42
(integer) 600
```

`SET key value NX EX 600` means: set this key **only if it does not exist** (`NX`), and make it
**expire in 600 seconds** (`EX`). Ana's command answered `OK`. Bia's, a moment later, answered
`(nil)`: the key existed, so nothing was set, and Bia's program knows the seat is taken. `TTL` says
how many seconds the hold has left.

That single command is **atomic**. Redis runs one command at a time, so two buyers asking for the
same seat in the same millisecond still get one `OK` and one `(nil)`, with no transaction and no
lock written by anybody. **The check and the write are one step**, which is exactly what the hot
row of lesson 1 was doing with an `UPDATE`, without holding anything for seven milliseconds.

The `--no-raw` flag asks `redis-cli` to print `(nil)` and `(integer)` as it does in an interactive
terminal; without it, a nil prints as an empty line.

## A hold that runs out

If the buyer abandons the payment, the hold must free itself. Here with a two-second hold so it
can be watched:

```
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw SET hold:show:1:seat:43 carla NX EX 2
OK
ana@lab:~/tickets$ sleep 3
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw GET hold:show:1:seat:43
(nil)
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw SET hold:show:1:seat:43 bia NX EX 600
OK
```

Three seconds later the key is gone, and Bia's hold succeeds. **No job deleted anything**; the
expiry is part of the key.

## Counting

`INCR` adds one to the number under a key, creating it at zero if it does not exist, and answers
the new value. It is atomic for the same reason `SET NX` is:

```
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw INCR views:show:1
(integer) 1
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw INCR views:show:1
(integer) 2
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw INCRBY views:show:1 10
(integer) 12
```

## How fast

Redis comes with its own benchmark. A hundred thousand `SET`s and a hundred thousand `GET`s, then
the same with sixteen commands sent per round trip (`-P 16`, pipelining):

```
ana@lab:~/tickets$ docker exec kv redis-benchmark --csv -t set,get -n 100000
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","110132.16","0.272","0.080","0.239","0.463","0.575","1.079"
"GET","97087.38","0.291","0.080","0.263","0.495","0.719","1.943"
ana@lab:~/tickets$ docker exec kv redis-benchmark --csv -t set,get -n 100000 -P 16
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","735294.06","1.013","0.264","0.943","1.559","1.679","2.391"
"GET","1408450.62","0.494","0.176","0.479","0.663","0.727","1.007"
```

About **110 000 `SET`s and 97 000 `GET`s a second** one at a time, with a median of a quarter of
a millisecond. With pipelining, **735 000 and 1 408 000**: almost all the cost of one command was
the round trip to the server, and sending sixteen per trip divided it by sixteen. It is the same
lesson as the line in lesson 1's `app.py` that saves 40 ms per request: **at this speed the network
is the bottleneck**, and batching is how to get around it.

These numbers are not comparable with PostgreSQL's pgbench in lesson 3, which ran transactions of
five statements written to disk. They measure different work, and that difference is the point:
Redis keeps everything in memory and does almost nothing per command.

## What it costs

Redis keeps its data in memory, so **the data set must fit in memory**, and a restart loses what
was not saved. It can save snapshots and a log of writes to disk, at some cost; for holds that
expire in ten minutes, losing them on a restart is often acceptable, and for the only copy of a
sale it never is. Remove the container when you are done:

```
ana@lab:~/tickets$ docker rm -f kv
kv
```
