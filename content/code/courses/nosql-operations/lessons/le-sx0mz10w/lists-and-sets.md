---
title: Lists for order, sets for membership
version: 1
---

A list and a set both hold several strings under one key, and they answer opposite questions. **A
list remembers order and allows repeats; a set forgets order and refuses repeats.** Picking the
wrong one shows up as a "recently viewed" box that shows the same keyboard three times, or a tag
lookup that has to read every product.

## "Recently viewed": a list with a length

Every product page Ana opens is pushed onto the left of her list, so the newest is first. She opened
the monitor, then the keyboard, the mouse, the cable and the keyboard again:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> LPUSH viewed:ana MN-330
(integer) 1
127.0.0.1:6379> LPUSH viewed:ana KB-101 MS-204 CB-012 KB-101
(integer) 5
127.0.0.1:6379> LRANGE viewed:ana 0 -1
1) "KB-101"
2) "CB-012"
3) "MS-204"
4) "KB-101"
5) "MN-330"
```

`LRANGE … 0 -1` reads the whole list, newest first, and the keyboard is there twice. For a "recently
viewed" box that is wrong. So before pushing a product the shop removes any earlier copy of it, and
after pushing it trims the list to the three the page shows:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> LREM viewed:ana 0 KB-101
(integer) 2
127.0.0.1:6379> LPUSH viewed:ana KB-101
(integer) 4
127.0.0.1:6379> LTRIM viewed:ana 0 2
OK
127.0.0.1:6379> LRANGE viewed:ana 0 -1
1) "KB-101"
2) "CB-012"
3) "MS-204"
```

`LREM … 0 KB-101` removed both copies (`2`), the push put one back at the front, and `LTRIM … 0 2`
kept positions 0 to 2 and dropped the rest. **After every view the list is back to three entries**,
however many pages Ana opens, which is what keeps a list per customer affordable for a million
customers.

The three commands are separate, so two page views at the same instant could interleave them. For
this box the worst outcome is a duplicate shown for one page load, and the shop accepts it. Where it
is not acceptable, `MULTI` and `EXEC` send the three as one transaction.

## A list is not a reliable queue

A list is also the obvious queue: the shop pushes a job, a worker pops it.

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> LPUSH jobs:email order-1001
(integer) 1
127.0.0.1:6379> RPOP jobs:email
"order-1001"
127.0.0.1:6379> LLEN jobs:email
(integer) 0
```

`RPOP` handed the job over and **removed it from Redis in the same step**. If the worker crashes
before the email goes out, the job is nowhere: not in the list, not anywhere else, and `LLEN` says
`0` as if all were well. Redis has a list-based workaround, `LMOVE`, which moves the job to a
second "in progress" list instead of deleting it, and the application then has to clean that list
up itself. The structure built for this problem is the stream, two sections on.

## Tags: a set per tag

A set answers "is this a member" and "what do these have in common" without the application reading
anything it does not need. One set per tag, holding product codes:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SADD tag:office KB-101 MS-204 MN-330 CB-012
(integer) 4
127.0.0.1:6379> SADD tag:usb-c CB-012 MN-330
(integer) 2
127.0.0.1:6379> SADD tag:wireless MS-204
(integer) 1
127.0.0.1:6379> SISMEMBER tag:wireless KB-101
(integer) 0
127.0.0.1:6379> SINTER tag:office tag:usb-c
1) "CB-012"
2) "MN-330"
127.0.0.1:6379> SADD tag:usb-c CB-012
(integer) 0
127.0.0.1:6379> SCARD tag:usb-c
(integer) 2
```

`SISMEMBER` asks one question about one product and answers `0` or `1`. `SINTER` intersects two tags
in the server: the products tagged both `office` and `usb-c`. And the second `SADD` of `CB-012`
answered `0`: it was already there, so nothing was added and `SCARD` still counts two. A set
cannot hold a duplicate, which is the property the "recently viewed" list had to fake with `LREM`.

## One thread, and the command that blocks it

Every command above touched a handful of members. **Redis runs one command at a time on one
thread**, which is what made `INCR` safe two sections ago, and it has a cost: a command is not
interrupted to let others run. `SMEMBERS` on a set of a million members, `SINTER` of two such sets,
`LRANGE … 0 -1` on a list nobody trimmed, `HGETALL` on a hash with every customer in it: each walks
the whole key while every other client waits.

Redis's documentation gives every command a time complexity, and it is worth reading before using
a command on a key that grows: `SISMEMBER` is O(1) whatever the size of the set, `SMEMBERS` is O(N).
A key that grows without limit is called a **big key**, and finding one before it causes a stall
is part of watching Redis, the subject of lesson 20.
