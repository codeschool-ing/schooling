---
title: Rebalancing, three ways
version: 1
---

**A rebalance is the group dealing its partitions again, and it happens every time a member joins
or leaves.** Starting a copy, stopping one, a copy crashing, a copy too slow to call `poll`: each
changes the membership, and the partitions are redistributed. While a partition is being moved, no
member reads it. How long that lasts, and how many partitions stop moving while it happens,
depends on the protocol.

To see only the assignments, without sales scrolling past, use a topic with nothing in it:

```sh
kafka-topics.sh --bootstrap-server localhost:9092 --create --topic quiet --partitions 3
```

In each of the three experiments below, start `a`, then `b` a few seconds later, then stop `b`
with Ctrl+C, wait a few seconds and stop `a`.

## Eager: everybody gives everything back

The **classic protocol** with the `range` strategy, the oldest arrangement, is called **eager**: at
every rebalance every member gives up all of its partitions, and then receives a new set.

```
ubuntu@stream:~/work$ python consumer.py a --group eager --topic quiet --strategy range
a: assigned [0, 1, 2]
a: revoked [0, 1, 2]
a: assigned [0, 1]
a: revoked [0, 1]
a: assigned [0, 1, 2]
a: revoked [0, 1, 2]
```

```
ubuntu@stream:~/work$ python consumer.py b --group eager --topic quiet --strategy range
b: assigned [2]
b: revoked [2]
```

When `b` joined, `a` gave back all three partitions and got 0 and 1 back; `b` got 2. When `b`
left, `a` gave back 0 and 1 and got all three. **Partitions 0 and 1 never needed to move, and
stopped anyway**, twice. With three partitions that costs a moment; with two hundred partitions and
fifty members, every member stopping for every join is a pause the whole group feels, and a
deployment that restarts the members one by one causes one pause per member.

## Cooperative: only what moves stops

The same classic protocol with the `cooperative-sticky` strategy is **incremental**: a member gives
up only the partitions that are going to someone else, and keeps reading the rest.

```
ubuntu@stream:~/work$ python consumer.py a --group coop --topic quiet --strategy cooperative-sticky
a: assigned [0, 1, 2]
a: revoked [0]
a: assigned []
a: assigned []
a: assigned [0]
a: revoked [0, 1, 2]
```

```
ubuntu@stream:~/work$ python consumer.py b --group coop --topic quiet --strategy cooperative-sticky
b: assigned []
b: assigned [0]
b: revoked [0]
```

When `b` joined, `a` gave up partition 0 alone and kept 1 and 2 throughout. With an incremental
protocol the callbacks report changes rather than the whole set: `assigned []` means "nothing new
for you this round", and `b`'s first `assigned []` is the round in which partition 0 was released
by `a` before it could be handed on. When `b` left, `a` was given 0 back, and its final `revoked`
lists all three because it was shutting down.

## The consumer protocol: the broker decides

Kafka 4 adds a new protocol, from KIP-848, the one lesson 1's console consumer kept mentioning. In
the classic protocol the members negotiate the assignment among themselves, through one of them
chosen as leader, and every change is a round of joining and syncing. In the **consumer
protocol** the broker's group coordinator computes the assignment and tells each member what to
add and drop, member by member, with no round that everybody has to finish. The Python client
supports it with `group.protocol=consumer`:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group new --members

GROUP           CONSUMER-ID            HOST            CLIENT-ID       #PARTITIONS     
new             G2evwjPYQXq2Gm+sayNIXA /127.0.0.1      rdkafka         1               
new             IugrKrUnSoaj4KhHbSVW5A /127.0.0.1      rdkafka         2               
```

That was with `a` and `b` both running. The member ids have a different shape, because the
coordinator issues them, and the partitions are split two and one, as before:

```
ubuntu@stream:~/work$ python consumer.py a --group new --topic quiet --protocol consumer
a: assigned [0, 1, 2]
a: revoked [2]
a: assigned []
a: assigned [2]
a: revoked [0, 1, 2]
```

```
ubuntu@stream:~/work$ python consumer.py b --group new --topic quiet --protocol consumer
b: assigned [2]
b: revoked [2]
```

`a` gave up partition 2 alone, `b` took it, and when `b` left, `a` got it back. The same
incremental behaviour as cooperative-sticky, decided in one place. With the consumer protocol the
`partition.assignment.strategy` setting does not apply at all, which is why `consumer.py` sets it
only for `classic`.

| | who computes the assignment | what stops during a change |
|---|---|---|
| classic, `range` (eager) | the group's leader member | every partition of every member |
| classic, `cooperative-sticky` | the group's leader member | only the partitions that move |
| consumer (KIP-848) | the broker's group coordinator | only the partitions that move |

**For a new application on Kafka 4, the consumer protocol is the one to choose**, as long as every
client library in the group supports it. librdkafka 2.16, under the Python client used here, does,
as the run above shows.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two timelines of member a while member b joins. Eager: a holds partitions 0, 1 and 2, gives all three back when b joins, and then holds 0 and 1 again, so every partition stops reading for a moment. Incremental, as in cooperative-sticky and the consumer protocol: a keeps 1 and 2 throughout and gives up only partition 0, which moves to b; only partition 0 stops.\" data-fig=\"l4-rebalance\"><line x1=\"330\" y1=\"30\" x2=\"330\" y2=\"215\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"330\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">b joins</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">eager</text><text x=\"130\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a holds</text><rect x=\"120\" y=\"60\" width=\"190\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">0, 1, 2</text><rect x=\"310\" y=\"60\" width=\"50\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></rect><text x=\"335\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nothing read</text><rect x=\"360\" y=\"60\" width=\"330\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">0, 1</text><rect x=\"360\" y=\"105\" width=\"330\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><text x=\"700\" y=\"117\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">b</text><text x=\"20\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">incremental</text><rect x=\"120\" y=\"155\" width=\"570\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1, 2</text><rect x=\"120\" y=\"185\" width=\"190\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">0</text><rect x=\"310\" y=\"185\" width=\"50\" height=\"24\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></rect><rect x=\"360\" y=\"185\" width=\"330\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"700\" y=\"197\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">b</text><text x=\"700\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">a</text><text x=\"700\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">a</text></svg>", "caption": "An eager rebalance stops every partition; an incremental one stops only the partitions that move."}
```
