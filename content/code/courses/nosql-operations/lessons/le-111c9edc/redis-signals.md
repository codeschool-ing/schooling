---
title: Redis, and the INFO lines that matter
version: 1
---

Redis is usually watched by its memory graph alone, and **memory near the limit is often a cache
working as designed**. What separates a healthy Redis from a sick one is what happens at the limit:
whether keys are evicted or writes refused, whether reads still find what they ask for, and whether
the replica is keeping up. `INFO` answers all of it, in about two hundred `name:value` lines, and
this section reads eight of them.

## A small Redis under pressure

The MongoDB set goes, and Redis comes back with a 20 MB ceiling, the `allkeys-lru` policy of
lesson 14, the latency monitor switched on, and a replica beside it:

```sh
docker rm -f mongo1 mongo2 mongo3 redis
docker run -d --name redis --network nosql redis:7.4 redis-server --maxmemory 20mb --maxmemory-policy allkeys-lru --latency-monitor-threshold 5
docker run -d --name redis-replica --network nosql redis:7.4 redis-server --replicaof redis 6379
```

The load is `redis-benchmark`, which ships in the image. `-t set,get` runs a round of `SET`s and
then a round of `GET`s, `-r 100000` spreads them over 100,000 random keys, and `-d 200` makes each
value 200 bytes. A hundred thousand values of that size do not fit in 20 MB, which is the point.
Started in the background, it leaves the terminal free for `redis-cli --stat`, a line a second
until it is stopped:

```
ana@vm:~$ docker exec -d redis redis-benchmark -t set,get -n 600000 -r 100000 -d 200 -q
ana@vm:~$ docker exec redis timeout 5 stdbuf -oL redis-cli --stat
------- data ------ --------------------- load -------------------- - child -
keys       mem      clients blocked requests            connections          
59404      20.03M   51      0       243703 (+0)         54          
59423      20.03M   51      0       350063 (+106360)    54          
59352      20.01M   51      0       461169 (+111106)    54          
59387      20.01M   51      0       576441 (+115272)    54          
56635      20.03M   51      0       695798 (+119357)    104         
```

`timeout 5` stops it after five seconds, and `stdbuf -oL` makes it print each line as it goes
rather than all at the end; at a terminal, `docker exec -it redis redis-cli --stat` and Ctrl+C do
the same. The key count stays near 59,400 while 100,000 keys are being written: **memory is pinned
at the ceiling, and the keys that do not fit are being evicted as fast as new ones arrive.**

## Eight lines of `INFO`

```
ana@vm:~$ docker exec redis redis-cli INFO | grep -E "^(used_memory|maxmemory|evicted_keys|keyspace_hits|keyspace_misses|connected_clients|rejected_connections|instantaneous_ops_per_sec):"
connected_clients:51
used_memory:20387416
maxmemory:20971520
instantaneous_ops_per_sec:116649
rejected_connections:0
evicted_keys:212690
keyspace_hits:122951
keyspace_misses:93717
```

| field | here | what it says |
|---|---|---|
| `used_memory` / `maxmemory` | 20,387,416 of 20,971,520 bytes, 97% | full, as a cache with a limit should be |
| `evicted_keys` | 212,690 | keys thrown out to make room since the start |
| `keyspace_hits` / `keyspace_misses` | 122,951 and 93,717 | reads that found their key, and reads that did not |
| `connected_clients` | 51, the benchmark's 50 and this one | the pool the applications hold open |
| `rejected_connections` | 0 | clients turned away at `maxclients` |
| `instantaneous_ops_per_sec` | 116,649 | commands per second, sampled over the last moments |

**The hit ratio is the number a cache is for**: 122,951 hits out of 216,668 reads is 56.7%. It is
close to the 59% of the 100,000 keys that fit, which is what random reads over a keyspace that does
not fit should give. Read the two fields together with the policy. Under `allkeys-lru`, a rising
`evicted_keys` with a steady hit ratio is a cache at work; a hit ratio that falls while evictions
climb means the working set has outgrown the memory, and every miss is now a trip to the database
behind it. **Under `noeviction` the same pressure is not evictions at all but errors**: writes
refused with `OOM`, which lesson 14 shows, and the field to watch is then `used_memory` itself.

## The replica, behind on purpose

`docker pause` freezes every process in a container without stopping it, which is a fair stand-in
for a replica that has stopped reading from its network. Write 200,000 keys while it is frozen:

```
ana@vm:~$ docker pause redis-replica
redis-replica
ana@vm:~$ docker exec redis redis-benchmark -t set -n 200000 -r 100000 -d 200 --csv
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","127388.53","0.260","0.104","0.231","0.471","0.655","4.751"
ana@vm:~$ docker exec redis redis-cli INFO replication | grep -E "^(slave0|master_repl_offset)"
slave0:ip=172.18.0.3,port=6379,state=online,offset=154056900,lag=2
master_repl_offset:205882318
ana@vm:~$ docker unpause redis-replica
redis-replica
ana@vm:~$ docker exec redis redis-cli INFO replication | grep -E "^(slave0|master_repl_offset)"
slave0:ip=172.18.0.3,port=6379,state=online,offset=205882318,lag=1
master_repl_offset:205882318
```

The writes did not slow down: 127,388 a second, with a p99 of 0.655 ms. The primary does not wait
for its replica (lesson 15), and so **nothing on the write path reports a replica in trouble.**

The replica line carries two different measurements, and they disagree about how bad it is:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 210\" role=\"img\" aria-label=\"The replication stream as a line of bytes. The primary has produced 205,882,318 bytes; the paused replica has acknowledged 154,056,900. The stretch between them, 51,825,418 bytes, is written on the primary and on no replica. Separately, lag=2 counts the seconds since the replica's last acknowledgement.\"><defs><marker id=\"l20off-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"40\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">replication stream, in bytes</text><rect x=\"40\" y=\"50\" width=\"463.9314290215054\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"503.9314290215054\" y=\"50\" width=\"156.06857097849462\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"271.9657145107527\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">acknowledged by the replica</text><text x=\"581.9657145107527\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">on the primary only</text><line x1=\"40\" y1=\"84\" x2=\"40\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"40\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"503.9314290215054\" y1=\"84\" x2=\"503.9314290215054\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"503.9314290215054\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">offset=154056900</text><line x1=\"660\" y1=\"84\" x2=\"660\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"656\" y=\"120\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">master_repl_offset:205882318</text><line x1=\"507.9314290215054\" y1=\"140\" x2=\"656\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l20off-ah-amber)\" marker-start=\"url(#l20off-ah-amber)\"></line><text x=\"581.9657145107527\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">51,825,418 bytes, about 49 MiB</text><text x=\"40\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lag=2: two seconds since the replica last answered</text><text x=\"40\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">it says nothing about how much is missing</text></svg>", "caption": "Two readings of one paused replica. The byte gap is how much would be lost; lag is only how long the replica has been quiet."}
```

`master_repl_offset` is how many bytes of the replication stream the primary has produced, and the
replica's `offset` is how many it has acknowledged. The gap is **51,825,418 bytes, about 49 MiB of
writes** that would be lost if the primary died at that moment. `lag` is something else: the seconds
since the replica last acknowledged anything, 2 here. A replica that is alive and acknowledging,
but slowly, shows a small `lag` and a growing byte gap, so the gap is the one to alert on. After the
unpause the two offsets are equal again, and `state=online` was there throughout, which is why
`state` is no alarm either.

## A client turned away

`rejected_connections` counts the clients Redis refused because `maxclients` was reached. To see
one, set the limit to 2, hold one connection open with a `BLPOP` that waits ten seconds for a list
nobody writes, and try a third:

```
ana@vm:~$ docker exec redis redis-cli CONFIG SET maxclients 2
OK
ana@vm:~$ docker exec -d redis redis-cli BLPOP nothing 10
ana@vm:~$ docker exec redis redis-cli PING
ERR max number of clients reached

ana@vm:~$ docker exec redis redis-cli INFO stats | grep rejected_connections
rejected_connections:1
ana@vm:~$ docker exec redis redis-cli CONFIG SET maxclients 10000
OK
```

The replica's own connection was the first of the two. The application sees the error once per
attempt; the counter keeps it after the application has retried and moved on, which is **why a
counter that only ever goes up is alerted on by its rate**, not its value.

## The slow log, and the latency doctor

Redis serves commands one at a time, so one slow command delays every client behind it. The slow
log keeps the commands that took longer than `slowlog-log-slower-than` microseconds, 10,000 by
default. With some sixty thousand keys nothing here is that slow, so the threshold goes down to one
millisecond for a moment, and `KEYS`, which walks every key, is run once:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG GET slowlog-log-slower-than
1) "slowlog-log-slower-than"
2) "10000"
127.0.0.1:6379> CONFIG SET slowlog-log-slower-than 1000
OK
127.0.0.1:6379> SLOWLOG RESET
OK
127.0.0.1:6379> KEYS order:*
(empty array)
127.0.0.1:6379> SLOWLOG GET 1
1) 1) (integer) 0
   2) (integer) 1791618161
   3) (integer) 4517
   4) 1) "KEYS"
      2) "order:*"
   5) "127.0.0.1:51936"
   6) ""
127.0.0.1:6379> CONFIG SET slowlog-log-slower-than 10000
OK
127.0.0.1:6379> LATENCY DOCTOR
Dave, no latency spike was observed during the lifetime of this Redis instance, not in the slightest bit. I honestly think you ought to sit down calmly, take a stress pill, and think things over.
127.0.0.1:6379> exit
```

Each entry is an id, the Unix time, **the duration in microseconds**, the command with its
arguments, the client's address and the client's name. `KEYS order:*` found nothing and still took
4,517 µs, because it had to look at every key to find nothing. On a production keyspace of millions
it takes seconds, during which Redis answers nobody; `SCAN` is the version that walks in small
steps.

`LATENCY DOCTOR` reads what the latency monitor recorded, events above the 5 ms the container was
started with, and writes a report in prose. On this run it saw nothing worth reporting and said so
in its own way. When it does see something, it names the kind of event, such as `command` or
`eviction-cycle`, with its average and worst time and a paragraph of advice. It needs
`latency-monitor-threshold` above zero, and the default is zero, so on most servers it has nothing
to say until somebody turns it on.
