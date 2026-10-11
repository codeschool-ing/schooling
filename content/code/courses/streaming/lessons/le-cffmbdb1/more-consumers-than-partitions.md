---
title: More consumers than partitions
version: 1
---

**A partition is read by at most one member of a group, so a group with more members than
partitions has members with nothing to do.** It is the most common surprise when people scale a
consumer: the topic has three partitions, the program is slow, somebody runs ten copies, and seven
of them sit idle while the other three are as slow as before.

The `shelf` group from two sections ago had four members on a topic of three partitions. Asked while
all four were running:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group shelf --members
```

`#PARTITIONS` is 1, 1, 1 and 0. And this is what the fourth member, `d`, printed between starting
and being stopped, while ten sales arrived:

```
ubuntu@stream:~/work$ python consumer.py d --group shelf
```

`d` joined, was given an empty list, and never read a message. It was not broken; it was a member
of the group, and it counted in every rebalance. **A member with no partitions is a standby**: if
one of the other three leaves, the next rebalance can give its partition to `d`, and the group keeps
three readers without anybody starting one.

## Ways out

There are only three, and they are worth knowing before the fourth copy is started:

| | what it does | what it costs |
|---|---|---|
| more partitions | lets more members read at once | moves keys, as lesson 3 showed; best decided when the topic is made |
| faster members | more work per member: batching writes downstream, fewer calls per message | engineering time |
| work inside a member | one consumer hands messages to a pool of threads | order per key holds only if each key always goes to the same thread |

The last one is how some systems get past the partition count, and it needs care: two messages
for Recife handled by two threads at once can finish in either order, which undoes exactly what the
partition was keeping. The partition count is a ceiling on parallel readers **of the log**; what a
reader does with each message is its own business, and its own risk.
