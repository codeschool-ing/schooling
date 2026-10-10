---
title: Backpressure, and a consumer that is thrown out of its group
version: 1
---

**In a pipeline where each stage pushes to the next, a slow stage has to push back.** If it does
not, the fast stage keeps sending, buffers fill, memory runs out and something falls over. That
pushing back is called **backpressure**, and systems built on pushing need a mechanism for it:
credits, bounded queues, a reply that says *stop for now*. Flink has one, between the operators of a
job, and lesson 13 meets it.

Kafka between a producer and a consumer does not, and does not need one. **Consumers pull.** A
consumer asks for messages when it is ready for them, so it is never sent more than it asked for,
and the producer never waits for it. What would have been a full buffer is the log itself, on disk,
sized in days rather than in megabytes. The last section showed it: the tills sent 600 sales in
thirty seconds while the consumer had handled half of them, and finished on time. **The log is the
buffer, and lag is how full it is.**

That moves the danger rather than removing it. A consumer that falls behind is not crashed by a
flood; it just gets further behind, which is why lag needs watching. And there is one place where a
slow consumer is punished directly, by its own group.

## Too slow between two polls

The group's coordinator has to know whether each member is alive. Two clocks decide it:

| setting | what it watches | default here |
|---|---|---|
| `session.timeout.ms` | heartbeats, which the client sends from a thread of its own | 45 s |
| `max.poll.interval.ms` | the time between two calls to `poll()` by your program | 300 s |

A consumer whose program goes longer than `max.poll.interval.ms` without polling is presumed stuck,
**and it leaves the group**: its partitions go to the other members, which is a rebalance. The idea
is sound. A program stuck in an infinite loop keeps sending heartbeats from the client's thread, and
only the poll interval catches it.

The trouble starts when the program is not stuck, only slow. Start two members of a group called
`audit`, both allowed six seconds between polls. In the second shell, a member that takes half a
second per sale:

```
ubuntu@stream:~/work$ python slow_consumer.py --group audit --delay 0.5 --max-poll 6000
```

And in the third, one that takes eight seconds per sale, as a call to a service having a bad day
might:

```
ubuntu@stream:~/work$ python slow_consumer.py --group audit --delay 8 --max-poll 6000
```

After half a minute, stop the slow one with Ctrl+C. Its screen:

```
ubuntu@stream:~/work$ python slow_consumer.py --group audit --delay 8 --max-poll 6000
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline of two members of one group. The slow member polls, receives a sale and works on it for eight seconds. At six seconds, the poll interval runs out and it leaves the group, which rebalances: the fast member's partitions are revoked and assigned again. At eight seconds the slow member polls, rejoins, and the next sale starts the same cycle.\" data-fig=\"l16-maxpoll\"><defs><marker id=\"l16-maxpoll-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">slow member</text><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fast member</text><text x=\"120\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><line x1=\"120\" y1=\"38\" x2=\"120\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"296\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">8 s</text><line x1=\"296\" y1=\"38\" x2=\"296\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"472\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">16 s</text><line x1=\"472\" y1=\"38\" x2=\"472\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"648\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24 s</text><line x1=\"648\" y1=\"38\" x2=\"648\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><rect x=\"122\" y=\"67\" width=\"172\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"208\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">8 s on one sale</text><line x1=\"252\" y1=\"58\" x2=\"252\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"128\" y=\"159\" width=\"160\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"288\" y=\"154\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 296 102 L 296 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l16-maxpoll-ah-83)\"></path><rect x=\"298\" y=\"67\" width=\"172\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><line x1=\"428\" y1=\"58\" x2=\"428\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"298\" y=\"159\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"464\" y=\"154\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 472 102 L 472 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l16-maxpoll-ah-83)\"></path><rect x=\"474\" y=\"67\" width=\"172\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><line x1=\"604\" y1=\"58\" x2=\"604\" y2=\"102\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><rect x=\"474\" y=\"159\" width=\"166\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"640\" y=\"154\" width=\"16\" height=\"32\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M 648 102 L 648 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l16-maxpoll-ah-83)\"></path><text x=\"252\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">6 s: leaves the group</text><text x=\"300\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">poll, rejoin</text><text x=\"208\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">handling sales</text><text x=\"296\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">rebalance</text></svg>", "caption": "Eight seconds of work against a six-second limit: every sale ends in a rebalance, and the member that was keeping up pays for it too."}
```

Read it as a loop. The member receives a sale and spends eight seconds on it. At six, the client
gives up on it and leaves the group, which is the line starting `%4|` that the client library writes
on its own. When the program finally polls again it gets the error, its partitions are revoked, it
rejoins and is handed partitions again, and the next sale starts the same eight seconds. **Every sale
costs a rebalance**, and the slow member makes some progress only because the client commits what
it has done when its partitions are taken away.

The cost does not stay with the slow member. The other one, which was keeping up, has its
partitions taken away and given back each time:

```
ubuntu@stream:~/work$ python slow_consumer.py --group audit --delay 0.5 --max-poll 6000
```

## What fixes it

Not a bigger cluster. The fixes are all in the consumer:

- **Make the gap between polls shorter than the limit with room to spare.** If a sale can take
  eight seconds, the limit cannot be six. The default, five minutes, is generous for a reason, and
  lowering it, as this demonstration did, is how most people meet this loop.
- **Take fewer messages per poll.** A client that fetches 500 records and handles them one by one
  before polling again needs 500 times the per-record time. The Java client's `max.poll.records`
  caps it; the Python client hands you one message per `poll()`, or as many as you ask `consume()` for.
- **Move the slow work off the polling thread**, and pause the partitions while it runs:
  `consumer.pause()` keeps the member polling, and alive, without fetching more. It is more code,
  and it is what long-running work needs.

The general rule is the one this whole section turns on: **a stream gives a slow consumer time, not
forgiveness**. Lag absorbs a slow hour. A member that cannot keep its promise to poll is removed, and
the removal itself is work the whole group pays for.
