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
```

```
ubuntu@stream:~/work$ python consumer.py b --group eager --topic quiet --strategy range
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
```

```
ubuntu@stream:~/work$ python consumer.py b --group coop --topic quiet --strategy cooperative-sticky
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
```

That was with `a` and `b` both running. The member ids have a different shape, because the
coordinator issues them, and the partitions are split two and one, as before:

```
ubuntu@stream:~/work$ python consumer.py a --group new --topic quiet --protocol consumer
```

```
ubuntu@stream:~/work$ python consumer.py b --group new --topic quiet --protocol consumer
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

@@fig:l4-rebalance@@
