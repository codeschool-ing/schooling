---
title: A consumer group shares the partitions
version: 1
---

**Copies of a program that use the same `group.id` share a topic's partitions between them: each
partition is read by exactly one member of the group.** That is how Kafka spreads the work of one
program over several processes or machines, and it is the queue-like behaviour lesson 2 promised:
inside a group, each message is handled once. Between groups nothing is shared. Every group reads
every message, at its own place, which is the log behaviour.

You need more shells for this one; open them as lesson 1 showed, with `multipass shell stream` in
more windows of your computer's terminal. In two of them, start two members of a new group,
`shelf`, one after the other: `python consumer.py a --group shelf` in one, and a few seconds later
`python consumer.py b --group shelf` in the next.

`a` started alone and read all ten sales from every partition, as `c1` did. When `b` joined, the
partitions were dealt again. In a third shell, ask who has what:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group shelf
```

Two members, told apart by `CONSUMER-ID`: one holds partitions 0 and 1, the other partition 2.
Three partitions between two members cannot be split evenly, and one member has two. The offsets
are those `a` reached reading alone, 4, 4 and 2, so whichever member now holds a partition carries
on from there; **the position belongs to the group, not to the member**.

Now start `python consumer.py c --group shelf` in another shell, and `d` the same way in one more,
and send ten more sales:

```
ubuntu@stream:~/work$ python producer.py
```

Then stop all four with Ctrl+C and look at what each one printed. `a` read the whole topic first,
alone, and then:

```
ubuntu@stream:~/work$ python consumer.py a --group shelf
```

```
ubuntu@stream:~/work$ python consumer.py b --group shelf
```

```
ubuntu@stream:~/work$ python consumer.py c --group shelf
```

**Each of the ten new sales was read once, by one member**: `a` read partition 2's two, `b`
partition 1's four, `c` partition 0's four. `b` began with partitions 0 and 1, gave up 0 when `c`
arrived, and kept 1. And `d` read nothing; the next section is about why.

@@fig:l4-group@@

## Two groups, two readers

Group `stock` from the last section was not affected by any of this. It is a different group, so
it has its own offsets, still at 4, 4 and 2, and the ten new sales are waiting for it. **Adding a
group never takes anything from another group.** That is how the four systems of lesson 2 read the
same sales: the stock system as one group, the loyalty scheme as another, each with as many members
as its own load needs.
