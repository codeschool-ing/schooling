---
title: A real cache on your own machine
version: 1
---

**moto creates a cache cluster and runs no cache, so this lesson brings its own.** Ubuntu packages
the Redis server, and Redis OSS speaks the protocol Valkey and ElastiCache speak. Everything from
here to the end of the lesson runs against a real server holding real keys in real memory. What it
cannot show is the managed half: no failover, no replica in another zone, no bill. **This is the
lesson's own addition to the lab**, and nothing after this lesson needs it.

## Install it, and keep it from starting on its own

```sh
sudo apt-get install -y redis-server
sudo systemctl disable --now redis-server
```

The package starts a Redis service of its own as soon as it is installed, and starts it again on
every boot. The second line stops it and keeps it stopped, so that, like moto, nothing runs unless
you start it. On WSL without systemd that line prints an error and there is nothing to stop, which
is fine.

## A third terminal

**Redis runs in a terminal of its own, the same way moto does.** Open one and type:

```sh
redis-server --port 6379 --save '' --appendonly no
```

It prints a few lines and waits. `--save ''` and `--appendonly no` turn off both of the ways Redis
can write to disk, so stopping it with `Ctrl+C` forgets every key, as stopping moto does. With no
password set it runs in protected mode, which refuses connections from any machine other than this
one. The moto terminal stays as it is, and you go on typing in the one where the lab's four lines
were typed.

## Keys that expire

`redis-cli` is the command line that came with the server. It sends one command and prints the
answer:

```
ana@laptop:~/aws$ redis-cli PING
PONG
ana@laptop:~/aws$ redis-cli INFO server | grep redis_version
redis_version:7.0.15
ana@laptop:~/aws$ redis-cli SET product:p-101 '{"name":"banana prata 1kg","price_cents":1290}' EX 300
OK
ana@laptop:~/aws$ redis-cli GET product:p-101
"{\"name\":\"banana prata 1kg\",\"price_cents\":1290}"
ana@laptop:~/aws$ redis-cli TTL product:p-101
(integer) 300
ana@laptop:~/aws$ redis-cli EXPIRE product:p-101 5
(integer) 1
ana@laptop:~/aws$ sleep 6; redis-cli GET product:p-101
(nil)
ana@laptop:~/aws$ redis-cli TTL product:p-101
(integer) -2
ana@laptop:~/aws$ redis-cli SET visits 1
OK
ana@laptop:~/aws$ redis-cli TTL visits
(integer) -1
```

**`EX 300` gave the key a time to live of five minutes**, and `TTL` counts it down. `EXPIRE`
replaced it with 5 seconds, and after `sleep 6` the key was gone: `GET` answered `(nil)` and `TTL`
answered `-2`, which means there is no such key. The key with no expiry answered `-1`. Those two
negative numbers are worth remembering, because they are how you tell "expired" from "never set to
expire" when you look at a cache that is misbehaving. Redis removes an expired key the moment
somebody asks for it, and a background sweep removes the ones nobody asks for.

**A key that never expires is how a cache fills with things nobody reads.** Every key a program puts
in a cache should carry a time to live, and the next two sections show what happens on both sides
of that rule.

## The client library

The programs in this lesson talk to Redis from Python, through the `redis` package. Install it in
the course's virtual environment, the one `source venv/bin/activate` switched on:

```
ana@laptop:~/aws$ pip install -q redis==8.1.0
ana@laptop:~/aws$ python3 -c "import redis; print(redis.__version__)"
8.1.0
```

Version 8.1.0 was published on 30 July 2026. The same package talks to Valkey and to ElastiCache
unchanged; on AWS, the host would be the cache's endpoint instead of `127.0.0.1`.
