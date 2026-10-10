---
title: Order, and a copy that never converges
version: 1
---

"Eventually the copies agree" quietly assumes that the copy applies the changes in the order they were
made. Lesson 7 showed that a broker does not promise that: a message is redelivered after a consumer
crashes, two consumers on one queue finish in either order, and a retry arrives after the message that
replaced it. The stock service can imitate the first case with `POST /resend`, which publishes an old
event again, late.

Set the coffee to 5 and then to 4, wait for the shops, and then let version 15 arrive again:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 5; curl -s -X PUT localhost:8001/stock/coffee -d 4
coffee: 5 in stock, version 15
coffee: 4 in stock, version 16
ana@vm:~/lab/eventual$ sleep 5; curl -s -X POST localhost:8001/resend/coffee/15
sent again: coffee = 5, version 15
ana@vm:~/lab/eventual$ sleep 3; curl -s localhost:8001/stock/coffee; curl -s localhost:8003/product/coffee
coffee: 4 in stock, version 16
shop-b: coffee: 5 left, version 15
```

The owner says 4. Shop `b` says 5, and **it will say 5 until the coffee changes again**, which may be
days. Its log shows why: it applied whatever arrived last.

```
ana@vm:~/lab/eventual$ docker compose logs shop-b --tail 3
shop-b-1  | shop-b: coffee = 5, version 15
shop-b-1  | shop-b: coffee = 4, version 16
shop-b-1  | shop-b: coffee = 5, version 15
```

This is worse than a window. A window closes; this copy has converged on a value that is wrong, and
from the outside nothing distinguishes it from a copy that is right. Eventual consistency was the
promise, and one late message was enough to break it.

## The copy needs the version too

The version from the previous sections fixes this as well, at the other end. An event that carries the
version it produced lets the copy refuse anything older than what it already holds. That is
`CHECK_VERSION=1`, which restarts the shops with the check on (and, since they keep everything in
memory, with empty copies):

```
ana@vm:~/lab/eventual$ CHECK_VERSION=1 docker compose up -d
 Container eventual-rabbitmq-1 Running 
 Container eventual-stock-1 Running 
 Container eventual-shop-a-1 Recreate 
 Container eventual-shop-b-1 Recreate 
 Container eventual-shop-a-1 Recreated 
 Container eventual-shop-b-1 Recreated 
 Container eventual-shop-b-1 Starting 
 Container eventual-shop-a-1 Starting 
 Container eventual-shop-b-1 Started 
 Container eventual-shop-a-1 Started 
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8001/stock/coffee -d 5; curl -s -X PUT localhost:8001/stock/coffee -d 4
coffee: 5 in stock, version 17
coffee: 4 in stock, version 18
ana@vm:~/lab/eventual$ sleep 5; curl -s -X POST localhost:8001/resend/coffee/17
sent again: coffee = 5, version 17
ana@vm:~/lab/eventual$ sleep 3; curl -s localhost:8001/stock/coffee; curl -s localhost:8003/product/coffee
coffee: 4 in stock, version 18
shop-b: coffee: 4 left, version 18
ana@vm:~/lab/eventual$ docker compose logs shop-b --tail 3
shop-b-1  | shop-b: coffee = 5, version 17
shop-b-1  | shop-b: coffee = 4, version 18
shop-b-1  | shop-b: ignored coffee version 17, already at 18
```

Version 17 arrived late, after 18, and shop `b` ignored it, so the copy and the owner agree. Lesson 7
said **designing events so that order does not matter is usually cheaper than guaranteeing it**, and this
is what it looks like. Each event carries the **whole state** of one thing ("coffee is 4, version 18")
rather than a change ("two bags sold"), and the copy keeps the newest version of each thing. Events in
any order, repeated any number of times, end in the same place.

Two conditions make it work, and both are easy to miss:

- **The version comes from the owner**, the one place that orders changes to that thing. A clock is not
  a version: two machines' clocks disagree, and "the latest timestamp" from two of them can be the
  older change. That is the problem of the next section.
- **A change has to be expressible as state.** "Two bags sold" applied twice sells four. If an event has
  to be a change, the copy needs lesson 7's idempotent consumer instead, and the events in order.
