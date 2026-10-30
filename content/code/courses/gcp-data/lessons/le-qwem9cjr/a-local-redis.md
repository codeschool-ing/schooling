---
title: A real cache on your own machine
version: 1
---

**There is no emulator for Memorystore, so this lesson brings the engine instead.** Ubuntu 24.04
packages Redis 7.0, and Memorystore for Redis offers 7.0 among its versions, so the server on your
laptop answers the same commands as the one Google would run for you. Everything from here to the
end of the lesson runs against a real server holding real keys in real memory. What it cannot show is
the managed half: no maintenance window, no replica in another zone that promotes itself, no bill.
**This is the lesson's own addition to the lab**, and nothing after this lesson needs it.

## Install it, and keep it from starting on its own

```sh
sudo apt-get install -y redis-server
sudo systemctl disable --now redis-server
```

The package starts a Redis service of its own as soon as it is installed, and starts it again on
every boot. The second line stops it and keeps it stopped, so that, like the emulators, nothing runs
unless you start it. On WSL without systemd that line prints an error and there is nothing to stop,
which is fine.

## A terminal of its own

**Redis runs in a terminal of its own, the same way the emulators do.** Open one and type:

```sh
redis-server --port 6379 --save '' --appendonly no
```

It prints a few lines and waits. `--save ''` and `--appendonly no` turn off both of the ways Redis
can write to disk, so stopping it with `Ctrl+C` forgets every key, as stopping an emulator does. With
no password set it runs in protected mode, which refuses connections from any machine other than this
one. You go on typing in the terminal where the lines of "Every time you open a terminal" were typed.

## Keys that expire

`redis-cli` is the command line that came with the server. It sends one command and prints the
answer:

```
ana@laptop:~/gcp$ redis-cli PING
PONG
ana@laptop:~/gcp$ redis-cli INFO server | grep redis_version
redis_version:7.0.15
ana@laptop:~/gcp$ redis-cli SET product:p-101 '{"name":"banana prata 1kg","price_cents":1290}' EX 300
OK
ana@laptop:~/gcp$ redis-cli GET product:p-101
"{\"name\":\"banana prata 1kg\",\"price_cents\":1290}"
ana@laptop:~/gcp$ redis-cli TTL product:p-101
(integer) 300
ana@laptop:~/gcp$ redis-cli EXPIRE product:p-101 5
(integer) 1
ana@laptop:~/gcp$ sleep 6; redis-cli GET product:p-101
(nil)
ana@laptop:~/gcp$ redis-cli TTL product:p-101
(integer) -2
ana@laptop:~/gcp$ redis-cli SET visits 1
OK
ana@laptop:~/gcp$ redis-cli TTL visits
(integer) -1
```

**`EX 300` gave the key a time to live of five minutes**, and `TTL` counts it down. `EXPIRE`
replaced it with 5 seconds, and after `sleep 6` the key was gone: `GET` answered `(nil)` and `TTL`
answered `-2`, which means there is no such key. The key with no expiry answered `-1`. Those two
negative numbers are worth remembering, because they are how you tell "expired" from "never set to
expire" when you look at a cache that is misbehaving. Redis removes an expired key the moment
somebody asks for it, and a background sweep removes the ones nobody asks for.

**A key that never expires is how a cache fills with things nobody reads.** Every key a program puts
in a cache should carry a time to live, and the next two sections show what happens on both sides of
that rule.

## The client library

The programs in this lesson talk to Redis from Python, through the `redis` package. Install it in the
course's virtual environment, the one `source venv/bin/activate` switched on:

```
ana@laptop:~/gcp$ pip install -q redis==8.1.0
ana@laptop:~/gcp$ python3 -c "import redis; print(redis.__version__)"
8.1.0
```

Version 8.1.0 was published on 30 July 2026. The same package talks to Memorystore for Redis and, in
its cluster mode, to Redis Cluster and Valkey. On Google Cloud the host would be the instance's
private address in your VPC instead of `127.0.0.1`: a Memorystore instance has no public address at
all, so the program that reads it runs in the same VPC network, the subject of `gcp-foundations`
lesson 15.
