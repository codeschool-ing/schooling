---
title: X to XII, parity, logs and admin tasks
version: 1
---

## X, dev/prod parity

The twelve-factor text names three gaps between development and production: **time**, code written
today and deployed weeks later; **people**, developers who write it and operators who deploy it; and
**tools**, SQLite on the laptop and PostgreSQL in production. The first two close with continuous
deployment and teams that run what they build. The third is the one a lesson can show.

The lab runs `postgres:17` because production would. A laptop with SQLite would pass every test and
still differ in exactly the places that hurt: SQLite accepts a string in an integer column unless the table
is declared `STRICT`, and its rules for locking under concurrent writes are its own.
**Containers made this factor cheap**: the same image of the same backing service runs on a laptop in
seconds, so there is no longer a good reason to develop against a lighter substitute.

## XI, logs as a stream

The catalogue writes one line per request to standard output and never opens a log file. It does not
know where its logs go, and that is the point: in the lab Docker collects them, and
`docker compose logs` reads them back, from every copy, in one stream:

```
ana@vm:~/lab/twelve$ docker compose logs catalogue --no-log-prefix | grep GET
a3b89e5e7e5f "GET /hits HTTP/1.1" 200 -
a3b89e5e7e5f "GET /hits HTTP/1.1" 200 -
a3b89e5e7e5f "GET /hits HTTP/1.1" 200 -
4ed40453cdac "GET /hits HTTP/1.1" 200 -
4ed40453cdac "GET /products HTTP/1.1" 200 -
280702d81305 "GET /hits HTTP/1.1" 200 -
```

In production the platform sends the same stream to a log store, where it can be searched across
every process and every service, and lesson 2's request id is what joins the lines of one request. A
program that writes to `/var/log/catalogue.log` inside its container writes to a disk that disappears
with the container, and that nobody is reading. **Write one event per line, and prefer a structured
format such as JSON** once something other than a person reads the logs; `scale` lesson 7 takes that
further.

## XII, admin tasks as one-off processes

The table was created by `python catalogue.py migrate`, run with `docker compose run --rm`: a one-off
process, from the same image, with the same configuration, that exits when it is done. Any admin task
works the same way, including a look at the data with the database's own client:

```
ana@vm:~/lab/twelve$ docker compose exec db psql -U quitanda -c "SELECT sku, price_cents FROM products ORDER BY price_cents DESC LIMIT 3"
  sku   | price_cents 
--------+-------------
 coffee |        3290
 cheese |        2450
 bread  |         990
(3 rows)
```

**The rule is that the task ships with the code and runs in the release's environment.** A migration
script kept on somebody's laptop runs against the wrong version of the schema, with the wrong
dependencies, sooner or later.

## What twelve leaves out

The list is from 2011, and some things it does not mention have become as basic as the rest: metrics
and traces for every service, health checks that tell the platform when a process is ready, security
of the supply chain, and designing the API before the code. Kevin Hoffman's *Beyond the Twelve-Factor
App*, in 2016, added three: API first, telemetry, and authentication and authorisation. The twelve
remain the floor rather than the ceiling.

Stop the lesson's services:

```sh
docker compose down -v
```
