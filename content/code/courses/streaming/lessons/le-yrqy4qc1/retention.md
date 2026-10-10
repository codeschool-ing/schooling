---
title: Retention, a segment at a time
version: 1
---

**Kafka deletes old messages by deleting whole segments, oldest first, and never touches the
active one.** A topic is told how long to keep data, or how much of it, and every so often the
broker looks for closed segments that are entirely past that limit and removes them. There is no
deleting one message, and no deleting a message because it was read: reading never removed
anything, and retention does not care who has read what.

These are the settings that decide it, as `sales` has them:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --describe --all --topic sales | grep -E "retention.(ms|bytes)|segment.(ms|bytes)|cleanup"
```

| setting | default here | what it decides |
|---|---|---|
| `cleanup.policy` | `delete` | delete old segments; `compact` is the next section |
| `retention.ms` | 604800000, seven days | a closed segment whose newest message is older than this goes |
| `retention.bytes` | −1, no limit | per partition: oldest segments go while the rest still exceeds it |
| `segment.bytes` | 1073741824, one gibibyte | when the active segment is closed for size |
| `segment.ms` | 604800000, seven days | when it is closed for age, even if it is small |

The `synonyms` beside each value say where it came from: a value set on the topic, or the
broker's default. **Retention is a property of the topic**, so `sales` can keep a week while an
audit topic keeps a year.

## Watching a segment go

A segment of a gibibyte would take a long time to fill with sales, so make a topic whose segments
close at one mebibyte, the smallest Kafka allows, and fill it with twenty thousand sales:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic old-sales --partitions 1 --config segment.bytes=1048576
```

SEGMENTS-PROSE

Now limit the topic to one mebibyte per partition:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --alter --topic old-sales --add-config retention.bytes=1048576
```

Nothing happens at once. **The broker checks retention every five minutes**
(`log.retention.check.interval.ms`, a broker setting), so a change takes effect at the next check.
Here it came within a minute; yours may take up to five. Then:

```
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic old-sales --time earliest
```

AFTER-PROSE

```
ubuntu@stream:~/work$ ls ~/kafka-data/node1/log/old-sales-0/*.log*
```

LATER-PROSE
