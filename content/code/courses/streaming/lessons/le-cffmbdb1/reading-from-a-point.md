---
title: Reading from a chosen point
version: 1
---

**A group's position is a value Kafka stores, so it can be set.** To read again from the beginning,
from an offset, or from a moment in time, you move the group's committed offsets, and the next
member to start reads from there. Lesson 2 called this **replay**; this section shows the two tools
for it, and lesson 16 uses them on a consumer that got something wrong.

## Moving a group with kafka-consumer-groups.sh

The group tool resets offsets, and it insists on two things: the group must have no running members,
and it changes nothing unless told to. `--dry-run` shows what would happen:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --topic sales --reset-offsets --to-earliest --dry-run
```

`--execute` does it. The target can be `--to-earliest`, `--to-latest`, `--to-offset`,
`--shift-by` a number, or `--to-datetime` a moment, and `--topic sales:1` limits it to one
partition. Move group `stock` back to offset 3 on partition 1 only:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --topic sales:1 --reset-offsets --to-offset 3 --execute
```

Then start `c1` again and stop it once it has read:

```
ubuntu@stream:~/work$ python consumer.py c1
```

Partition 1 started at 3, so `nat-000008`, which `c1` read in the first section, came round again
before the new sales. Partitions 0 and 2 were not touched and resumed at 4 and 2, reading only the
ten sales sent while `c1` was away. **A reset moves the place, and the log supplies the messages**:
nothing was re-sent, and no other group noticed.

## Reading from a moment, without a group

A program can also choose its own starting point, with no group position involved. `offsets_for_times`
asks the broker, for each partition, for the first offset whose timestamp is at or after a given
moment, using the `.timeindex` from lesson 3. Save this as `~/work/rewind.py`:

@@EX@@

Note the time, send five more sales, and rewind to that time:

```
ubuntu@stream:~/work$ date "+%F %T"
```

The broker answered offsets 8, 8 and 4: exactly the log-end offsets before the five new sales, so
the program read those five and nothing older. Your time will be different; use the one your
`date` printed. The timestamp the broker looks up is the record's, set by the producer when it
sent the message, and not the sale's own `at`; lesson 9 is about the difference, and about
producers that set it to something else.

`rewind.py` uses `assign` instead of `subscribe`. **An assigned consumer is not a member of any
group**: it reads the partitions it names, no rebalance gives them to anyone else, and it commits
nothing, because `enable.auto.commit` is off. It is the tool for looking, while a reset group is the
tool for reprocessing.
