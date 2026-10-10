---
title: Streams, events that wait for an acknowledgement
version: 1
---

The list in the section on lists and sets lost a job because popping it deleted it. **A stream
never deletes an entry because somebody read it.** It is an append-only log of entries, each with an
id and a few fields, and readers keep their place in it rather than consuming it. A **consumer
group** shares the entries out among workers and remembers which ones each worker has been given and
not yet confirmed, so a job a worker took and never finished is still there to be found.

## Three orders, two workers

The shop appends an event to the stream `orders` each time an order is placed. The shipping team's
workers form a group called `shipping` and read from it:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> XADD orders * order 1001 customer ana total_cents 34990
"1791617490336-0"
127.0.0.1:6379> XADD orders * order 1002 customer bruno total_cents 18900
"1791617490337-0"
127.0.0.1:6379> XADD orders * order 1003 customer carla total_cents 149900
"1791617490337-1"
127.0.0.1:6379> XLEN orders
(integer) 3
127.0.0.1:6379> XGROUP CREATE orders shipping 0
OK
127.0.0.1:6379> XREADGROUP GROUP shipping worker-1 COUNT 2 STREAMS orders >
1) 1) "orders"
   2) 1) 1) "1791617490336-0"
         2) 1) "order"
            2) "1001"
            3) "customer"
            4) "ana"
            5) "total_cents"
            6) "34990"
      2) 1) "1791617490337-0"
         2) 1) "order"
            2) "1002"
            3) "customer"
            4) "bruno"
            5) "total_cents"
            6) "18900"
127.0.0.1:6379> XREADGROUP GROUP shipping worker-2 COUNT 2 STREAMS orders >
1) 1) "orders"
   2) 1) 1) "1791617490337-1"
         2) 1) "order"
            2) "1003"
            3) "customer"
            4) "carla"
            5) "total_cents"
            6) "149900"
```

`XADD orders *` appended an entry and let Redis choose its id: the time in milliseconds, a dash and a
sequence number for entries in the same millisecond, which is why two of them end in `-0` and `-1`.
Ids only grow, so the stream is in the order the events arrived.

`XGROUP CREATE orders shipping 0` created the group at the start of the stream, so it will see the
three entries already there; `$` instead of `0` would have started it at the end, with only new
events. In `XREADGROUP`, the `>` means "entries this group has not yet handed to anybody". `worker-1`
asked for two and got orders 1001 and 1002; `worker-2` asked for two and got the only one left,
1003. **Each entry went to exactly one worker of the group.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 310\" role=\"img\" aria-label=\"The stream orders drawn as three entries in a row, for orders 1001, 1002 and 1003, oldest on the left. Below it, two consumer groups. The shipping group's pointer stands after entry 1003, since it has handed out all three; its pending entries list holds 1001 and 1002, given to worker-1 and not acknowledged, while 1003 was acknowledged by worker-2. The billing group's pointer stands before the first entry, with a lag of three, and nothing pending.\"><defs><marker id=\"l12stream-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l12stream-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">stream</text><text x=\"70\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders</text><rect x=\"60\" y=\"40\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">order 1001</text><text x=\"145.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">…-0</text><rect x=\"250\" y=\"40\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"335.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">order 1002</text><text x=\"335.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">…-0</text><rect x=\"440\" y=\"40\" width=\"170\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"525.0\" y=\"57.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">order 1003</text><text x=\"525.0\" y=\"72.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">…-1</text><line x1=\"625\" y1=\"65\" x2=\"680\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12stream-ah-paper-dim)\" stroke-dasharray=\"4 3\"></line><text x=\"652\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">new entries</text><rect x=\"20\" y=\"130\" width=\"400\" height=\"150\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">group</text><text x=\"72\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shipping</text><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">position: after 1003, lag 0</text><path d=\"M 420 140 L 616 140 L 616 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12stream-ah-phosphor)\"></path><rect x=\"40\" y=\"190\" width=\"170\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pending</text><text x=\"125.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1001 → worker-1</text><text x=\"125.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1002 → worker-1</text><rect x=\"230\" y=\"190\" width=\"170\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">acknowledged</text><text x=\"315.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1003 ← worker-2</text><text x=\"315.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">left the pending list</text><rect x=\"440\" y=\"160\" width=\"240\" height=\"120\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"450\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">group</text><text x=\"492\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">billing</text><text x=\"450\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">position: before 1001, lag 3</text><text x=\"450\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nothing pending</text><path d=\"M 560 280 L 560 298 L 8 298 L 8 65 L 56 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12stream-ah-paper-dim)\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "One stream, two groups. Each group has its own position in the stream and its own list of entries handed out and not yet acknowledged; the entries themselves stay in the stream either way."}
```

## Acknowledged, pending, and claimed

Being handed an entry is not finishing it. A worker that has shipped an order says so with `XACK`,
and until then the entry sits in the group's **pending entries list**, with the name of the worker
that has it, how long ago it was handed over and how many times it has been. Here `worker-2` ships
order 1003 and acknowledges it, and `worker-1` crashes holding the other two:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> XACK orders shipping 1791617490337-1
(integer) 1
127.0.0.1:6379> XPENDING orders shipping
1) (integer) 2
2) "1791617490336-0"
3) "1791617490337-0"
4) 1) 1) "worker-1"
      2) "2"
127.0.0.1:6379> XPENDING orders shipping - + 10
1) 1) "1791617490336-0"
   2) "worker-1"
   3) (integer) 6190
   4) (integer) 1
2) 1) "1791617490337-0"
   2) "worker-1"
   3) (integer) 6190
   4) (integer) 1
127.0.0.1:6379> XAUTOCLAIM orders shipping worker-2 5000 0 COUNT 10
1) "0-0"
2) 1) 1) "1791617490336-0"
      2) 1) "order"
         2) "1001"
         3) "customer"
         4) "ana"
         5) "total_cents"
         6) "34990"
   2) 1) "1791617490337-0"
      2) 1) "order"
         2) "1002"
         3) "customer"
         4) "bruno"
         5) "total_cents"
         6) "18900"
3) (empty array)
127.0.0.1:6379> XPENDING orders shipping - + 10
1) 1) "1791617490336-0"
   2) "worker-2"
   3) (integer) 1
   4) (integer) 2
2) 1) "1791617490337-0"
   2) "worker-2"
   3) (integer) 1
   4) (integer) 2
127.0.0.1:6379> XACK orders shipping 1791617490336-0 1791617490337-0
(integer) 2
127.0.0.1:6379> XLEN orders
(integer) 3
127.0.0.1:6379> XGROUP CREATE orders billing 0
OK
127.0.0.1:6379> XINFO GROUPS orders
1)  1) "name"
    2) "billing"
    3) "consumers"
    4) (integer) 0
    5) "pending"
    6) (integer) 0
    7) "last-delivered-id"
    8) "0-0"
    9) "entries-read"
   10) (nil)
   11) "lag"
   12) (integer) 3
2)  1) "name"
    2) "shipping"
    3) "consumers"
    4) (integer) 2
    5) "pending"
    6) (integer) 0
    7) "last-delivered-id"
    8) "1791617490337-1"
    9) "entries-read"
   10) (integer) 3
   11) "lag"
   12) (integer) 0
```

Read the session in order:

1. `XACK` returned `1`: the entry for order 1003 left the pending list.
2. The summary form of `XPENDING` reported **2 entries pending, both held by `worker-1`**.
3. Six seconds later the detailed form showed each one idle for over 6,000 milliseconds, delivered
   once. Nothing in Redis watches that number: an entry whose worker died stays pending for ever,
   and no other worker of the group will receive it with `>`, because the group has already
   handed it out.
4. `XAUTOCLAIM … worker-2 5000 0` is how it gets unstuck: `worker-2` took over every entry idle for
   more than 5,000 ms, and received them in full.
5. The pending list now names `worker-2`, the idle time restarted, and the **delivery count went to
   2**. A count that keeps climbing is an event that crashes every worker that touches it. A worker
   that sees a count above a limit the shop chooses moves the entry to a separate stream for a
   person to look at, instead of crashing on it again.
6. Two `XACK`s later the pending list is empty, and `XLEN` still says 3. **Acknowledging an entry does
   not delete it.** A stream grows until it is trimmed, with `XADD orders MAXLEN ~ 100000 * …` on
   every append or `XTRIM` from time to time, and an untrimmed stream is a big key that keeps growing.

The last two lines are the other reason streams exist. A second group, `billing`, was created at the
start of the same stream. `XINFO GROUPS` shows the two side by side: `shipping` has delivered
everything and its lag is 0; `billing` has delivered nothing and its lag is 3. **Each group reads the
whole stream at its own pace**, so the billing service and the shipping service both see every
order without the shop writing each event twice.

## What a stream is not

A stream lives in the memory of one Redis, like every key in this lesson. Whether its entries survive
that Redis restarting is the subject of lesson 13, and whether they survive a failover to a replica
is the subject of lesson 15. Neither answer is "always". For events the business cannot lose, such
as a payment taken, a stream in Redis is a fast way to hand work out, and the record of truth is
still written somewhere that was built to keep it.
