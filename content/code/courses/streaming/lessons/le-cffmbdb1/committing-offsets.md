---
title: Committing an offset, and when it happens
version: 1
---

**A commit records, for a group and a partition, the offset the group should read next.** It is the
group's place in the log, the same thing `minilog.py`'s place files held in lesson 2, and it is the
only thing a consumer that restarts has to go on. What matters is not that commits happen but
**when, relative to the work**: a commit says "everything before this is done", and if it is not
true at the moment of a crash, the restart either repeats work or skips it.

Kafka keeps commits in a topic of its own, `__consumer_offsets`:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic __consumer_offsets | head -1
```

Fifty partitions, and `cleanup.policy=compact`: each group's latest commit for each partition is the
value for a key, and lesson 3's compaction keeps only the latest. A commit is a message like any
other.

## Automatic commits

By default the client commits for you. **`enable.auto.commit` is on, and every five seconds**
(`auto.commit.interval.ms`) the client commits the offsets of the messages `poll` has returned so
far. Five seconds is a window, and a crash inside it shows what the window means. Start a consumer
in a new group, `auto`, and kill it with `kill -9` from another shell about four seconds later, as a
power cut would:

```
ubuntu@stream:~/work$ python consumer.py x --group auto
```

`x` read all twenty sales in the topic and printed them, and the shell printed `Killed`. Now ask
what the group committed:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group auto
```

**`CURRENT-OFFSET` is `-` for every partition: nothing was committed.** The member is still listed,
because Kafka has not yet noticed it is gone; the broker waits for its session to time out, 45
seconds by default (`session.timeout.ms`). When a new member of `auto` starts, it finds no commit,
falls back to `auto.offset.reset`, and reads all twenty sales again. If `x` had been adding sales to
a total, the total would now count them twice.

## Committing yourself

With `--manual`, `consumer.py` turns automatic commits off and commits after each message, waiting
for the broker to confirm. Same experiment, group `manual`:

```
ubuntu@stream:~/work$ python consumer.py y --group manual --manual
```

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group manual
```

Committed 8, 8 and 4: everything `y` printed is recorded, and a restart would read nothing twice.
Committing after every message costs a round trip to the broker per message, which is why real
consumers commit after a batch instead. Then a crash repeats at most one batch.

@@fig:l4-commit@@

Neither choice removes the problem; each moves it. Committing **after** the work, as `--manual`
does, means a crash between the work and the commit repeats that message: **at least once**.
Committing **before** the work means a crash between the commit and the work loses it: **at most
once**. Lesson 7 makes both crash on purpose and counts the damage, and lesson 8 makes repeated work
harmless, which is the usual way out.
