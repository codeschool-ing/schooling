---
title: A consumer, and the loop it lives in
version: 1
---

**A consumer asks for messages; Kafka never pushes them.** The program calls `poll` in a loop, and
each call returns the next message from one of the partitions it has been given, or nothing if
none arrived within the timeout. Everything else a consumer does, joining a group, being given
partitions and recording how far it has read, happens inside those calls, so a consumer that stops
calling `poll` stops being a consumer, which lesson 16 shows.

Every consumer in this course belongs to a **consumer group**, named by `group.id`. The group is
what Kafka keeps the reading position for, and what it shares partitions between, which is the next
section. Save this as `~/work/consumer.py`:

@@EX@@

Run it in your second shell. It reads the ten sales from the last section and waits for more; stop
it with Ctrl+C when it has:

```
ubuntu@stream:~/work$ python consumer.py c1
```

The first line is the assignment: alone in group `stock`, `c1` was given all three partitions. Then
the ten sales, in an order worth reading. **Within each partition they are in offset order**:
partition 2's two Recife sales, then partition 1's four, then partition 0's four. Across partitions
there is no order at all; the client happened to fetch partition 2 first, and Olinda's sale
`oli-000001`, the first one produced, came out eighth. Lesson 2's promise was order per key, and
that is exactly what arrived.

Ctrl+C ended the loop, and `close` handed the partitions back, which is the `revoked` line. It also
recorded how far `c1` had read. Ask Kafka what it knows about the group:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group stock
```

The group has no members now, and Kafka still remembers it. For each partition,
**`CURRENT-OFFSET` is the offset the group will read next**, `LOG-END-OFFSET` is the offset the
next message produced will get, and **`LAG`** is the difference: messages written and not yet read
by this group. All three are 0, because `c1` read everything. Run `consumer.py c1` again and it
prints the assignment and nothing else: the group resumes at 4, 4 and 2.

## Where a new group starts

A group that has never committed an offset has nowhere to resume from, and
**`auto.offset.reset`** decides: `earliest` starts at the beginning of each partition, and `latest`,
the default, starts at the end, so the group sees only messages produced after it joined. Lesson 1's
console consumer started at the end for the same reason. `consumer.py` sets `earliest`, so a new
group name reads everything there is, which is what the next sections rely on.
