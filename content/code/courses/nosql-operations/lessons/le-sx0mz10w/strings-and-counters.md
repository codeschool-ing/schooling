---
title: Strings, counters and a key that says no
version: 1
---

The commonest way to use Redis badly is to treat it as a box of strings: read a value into the
application, change it there, write it back. **Every structure in this lesson exists so that the
change happens inside the server instead**, in one command that nothing else can interrupt. This
section shows what the box-of-strings habit costs, and then the three things a plain string does
well: a counter, a key that refuses to be written twice, and a key that removes itself.

If you took `servers-cache`, its lesson 8 put Redis in front of a web server as a cache. This
lesson and the next three treat it as the shop's database, where losing a value is an incident
rather than a slower page.

## The container

This lesson needs only the `redis` container from lesson 1, and it is clearer from empty. Remove
the old one and start a fresh one on the same network:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql redis:7.4
194cfe171852b49e160160b99aa35766e36dc7582d7e259173dbec41cc983ea5
```

Every session below is typed at `redis-cli` inside that container. Nothing else is installed.

## Two clients, one counter

Two workers each count 500 page views. Each one reads the counter, adds one in the shell, and
writes the result back, which is exactly what an application does when it treats Redis as a box:

```
ana@vm:~$ docker exec redis redis-cli SET visits 0
OK
ana@vm:~$ for w in 1 2; do docker exec redis sh -c 'for i in $(seq 500); do v=$(redis-cli GET visits); redis-cli SET visits $((v+1)) >/dev/null; done' & done; wait
```

**1,000 increments went in and 554 came out.** Both workers read the same value, both added one
to it, and both wrote back the same number, so one of the two increments vanished. Nothing
reported an error; the 446 views are simply gone. Redis did nothing wrong: it ran every `GET` and
every `SET` in the order they arrived, and the race was between them, in the workers.

The same two workers, asking Redis to do the addition:

```
ana@vm:~$ docker exec redis redis-cli GET visits
554
ana@vm:~$ docker exec redis redis-cli SET visits 0
```

**Redis runs commands one at a time, on one thread**, so `INCR` reads, adds and writes with nothing
able to run in between. That is the property every structure in this lesson leans on, and it is
also the reason a single slow command stalls every client at once, which the section on sets
comes back to.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Two timelines side by side. On the left, worker 1 and worker 2 each send GET to Redis and both receive 41; then each sends SET 42, and the counter ends at 42 after two increments, one of them lost. On the right, each worker sends INCR; Redis answers 42 to the first and 43 to the second, and the counter ends at 43.\"><defs><marker id=\"l12race-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12race-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12race-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">read, add one, write back</text><text x=\"50\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 1</text><line x1=\"50\" y1=\"50\" x2=\"50\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Redis</text><line x1=\"170\" y1=\"50\" x2=\"170\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"290\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 2</text><line x1=\"290\" y1=\"50\" x2=\"290\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"50\" y1=\"62\" x2=\"168\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-phosphor)\"></line><text x=\"104.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET</text><line x1=\"170\" y1=\"80\" x2=\"52\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-paper-dim)\"></line><text x=\"104.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">41</text><line x1=\"290\" y1=\"100\" x2=\"172\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-phosphor)\"></line><text x=\"236.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET</text><line x1=\"170\" y1=\"118\" x2=\"288\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-paper-dim)\"></line><text x=\"236.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">41</text><line x1=\"50\" y1=\"145\" x2=\"168\" y2=\"153\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-amber)\"></line><text x=\"104.0\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SET 42</text><line x1=\"290\" y1=\"170\" x2=\"172\" y2=\"178\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-amber)\"></line><text x=\"236.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SET 42</text><text x=\"170\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">visits = 42: one increment lost</text><text x=\"530\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">INCR, inside the server</text><text x=\"410\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 1</text><line x1=\"410\" y1=\"50\" x2=\"410\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"530\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Redis</text><line x1=\"530\" y1=\"50\" x2=\"530\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"650\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 2</text><line x1=\"650\" y1=\"50\" x2=\"650\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"410\" y1=\"62\" x2=\"528\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-phosphor)\"></line><text x=\"464.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">INCR</text><line x1=\"530\" y1=\"80\" x2=\"412\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-paper-dim)\"></line><text x=\"464.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">42</text><line x1=\"650\" y1=\"100\" x2=\"532\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-phosphor)\"></line><text x=\"596.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">INCR</text><line x1=\"530\" y1=\"118\" x2=\"648\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-paper-dim)\"></line><text x=\"596.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">43</text><text x=\"530\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">visits = 43: both counted</text><text x=\"170\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">counter starts at 41</text><text x=\"530\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">counter starts at 41</text></svg>", "caption": "Read, add, write back: both workers read 41 and both write 42. With INCR the addition happens inside Redis, one command at a time, and neither increment is lost."}
```

## Counters for stock

A string that holds an integer is a counter. The shop's stock of keyboards:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET stock:KB-101 12
OK
127.0.0.1:6379> DECR stock:KB-101
(integer) 11
127.0.0.1:6379> DECRBY stock:KB-101 3
(integer) 8
127.0.0.1:6379> GET stock:KB-101
"8"
127.0.0.1:6379> OBJECT ENCODING stock:KB-101
"int"
127.0.0.1:6379> SET greeting "hello from the lab"
OK
127.0.0.1:6379> INCR greeting
(error) ERR value is not an integer or out of range
```

`DECR` and `DECRBY` answer with the new value, so the application learns the stock left in the same
round trip that took one out. `OBJECT ENCODING` shows that Redis stored `12` as a machine integer,
`int`, not as two characters. And a counter only counts numbers: `INCR` on a string that is not
an integer refuses with an error rather than guessing.

A stock counter that can go below zero is a bug waiting for the last unit. `DECR` does not stop at
zero; an application either checks the answer and puts the unit back with `INCR`, or runs the check
and the decrement together in a short Lua script, which Redis also runs as one command.

## A key that says no: locks and idempotency

`SET` takes two options that turn it into a question. **`NX` writes only if the key does not
exist, and `EX` gives the key a lifetime in seconds.** Together they make the smallest useful lock:
two workers want to process order 1001, and only one may.

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET lock:order:1001 worker-a NX EX 30
OK
127.0.0.1:6379> SET lock:order:1001 worker-b NX EX 30
(nil)
127.0.0.1:6379> GET lock:order:1001
"worker-a"
127.0.0.1:6379> TTL lock:order:1001
(integer) 30
```

`worker-a` got `OK` and `worker-b` got `(nil)`, which is Redis saying "not written". The lock lives
for 30 seconds whatever happens, so a worker that crashes while holding it does not hold it for
ever.

Releasing it has a trap. A plain `DEL` deletes the lock whoever owns it, and a worker that ran past
its 30 seconds would delete the lock another worker took after it expired. So the release checks the
owner and deletes in one step, in Lua:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end" 1 lock:order:1001 worker-b
(integer) 0
127.0.0.1:6379> EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end" 1 lock:order:1001 worker-a
(integer) 1
```

`worker-b`'s release did nothing (`0`); `worker-a`'s deleted the key (`1`). The script is one
command, so no other client can take the lock between the check and the delete.

The same `SET … NX EX` is an **idempotency key**. A client that times out retries, so a payment
service receives the same request twice. It records that it has charged order 1001, and refuses the
second attempt:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET done:payment:1001 charged NX EX 86400
OK
127.0.0.1:6379> SET done:payment:1001 charged NX EX 86400
(nil)
```

The first call wrote the key and the charge goes ahead; the retry is told the key exists and is
answered with the first result instead of a second charge. The key expires after a day, by which
time no client is still retrying.

Both patterns rest on one Redis being the only judge. **Lesson 15 loses an acknowledged write on
purpose during a failover**, and a lock or an idempotency key is a write like any other: if the
copy that held it is the one that loses it, two workers can each believe they hold the lock.

## A lifetime belongs to the key, and `SET` throws it away

`EX` sets a lifetime, and `TTL` reads how many seconds are left. The surprise is what an ordinary
`SET` does to a key that already has one:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET cart:ana KB-101 EX 600
OK
127.0.0.1:6379> TTL cart:ana
(integer) 600
127.0.0.1:6379> SET cart:ana MS-204
OK
127.0.0.1:6379> TTL cart:ana
(integer) -1
127.0.0.1:6379> SET cart:ana KB-101 EX 600
OK
127.0.0.1:6379> SET cart:ana MS-204 KEEPTTL
OK
127.0.0.1:6379> TTL cart:ana
(integer) 600
```

**A plain `SET` replaced the value and removed the expiry**: `TTL` answered `-1`, which means the
key now lives until somebody deletes it. A shopping cart meant to vanish after ten minutes of
inactivity is now permanent, and nothing failed. `KEEPTTL` keeps the old lifetime. Lesson 14 is
about expiry in full: what `-1` and `-2` mean, and when an expired key actually leaves memory.
