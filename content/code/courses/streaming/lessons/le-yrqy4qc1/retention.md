---
title: Retention, a segment at a time
version: 1
---

**Kafka deletes old messages by deleting whole segments, oldest first.** The one still being
written goes only when time retention has passed everything in it; Kafka then closes it first, and
lesson 9 describes that case. A topic is told how long to keep data, or how much of it, and every so often the
broker looks for closed segments that are entirely past that limit and removes them. There is no
deleting one message, and no deleting a message because it was read: reading never removed
anything, and retention does not care who has read what.

These are the settings that decide it, as `sales` has them:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --describe --all --topic sales | grep -E "retention.(ms|bytes)|segment.(ms|bytes)|cleanup"
  cleanup.policy=delete sensitive=false synonyms={DEFAULT_CONFIG:log.cleanup.policy=delete}
  delete.retention.ms=86400000 sensitive=false synonyms={DEFAULT_CONFIG:log.cleaner.delete.retention.ms=86400000}
  local.retention.bytes=-2 sensitive=false synonyms={DEFAULT_CONFIG:log.local.retention.bytes=-2}
  local.retention.ms=-2 sensitive=false synonyms={DEFAULT_CONFIG:log.local.retention.ms=-2}
  retention.bytes=-1 sensitive=false synonyms={DEFAULT_CONFIG:log.retention.bytes=-1}
  retention.ms=604800000 sensitive=false synonyms={}
  segment.bytes=1073741824 sensitive=false synonyms={DEFAULT_CONFIG:log.segment.bytes=1073741824}
  segment.ms=604800000 sensitive=false synonyms={}
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
Created topic old-sales.
ubuntu@stream:~/work$ python tills.py --topic old-sales --count 20000 --rate 0
sent 20000 sales to old-sales, the last one at 19:30:14
ubuntu@stream:~/work$ ls ~/kafka-data/node1/log/old-sales-0/*.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000000000.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000007081.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000014354.log
```

Twenty thousand sales filled three segments. The names are the base offsets: the first segment
holds offsets 0 to 7080, the second starts at 7081 and the third, the active one, at 14354.

Now limit the topic to one mebibyte per partition:

```
ubuntu@stream:~/work$ kafka-configs.sh --bootstrap-server localhost:9092 --alter --topic old-sales --add-config retention.bytes=1048576
Completed updating config for topic old-sales.
```

Nothing happens at once. **The broker checks retention every five minutes**
(`log.retention.check.interval.ms`, a broker setting), so a change takes effect at the next check.
Allow up to five minutes, then:

```
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic old-sales --time earliest
old-sales:0:7081
ubuntu@stream:~/work$ ls ~/kafka-data/node1/log/old-sales-0/*.log*
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000000000.log.deleted
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000007081.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000014354.log
```

The earliest offset is now 7081. **The first segment was deleted whole**, and with it the 7 081
sales in it; the topic's log start offset moved to the second segment's base offset. The rule for
`retention.bytes` is: while the partition minus its oldest segment would still be above the limit,
delete the oldest segment. Two full segments of a mebibyte and a part-full active one, minus the
oldest, are still above one mebibyte, so the first went; minus the second as well, only the active
segment would be left, below the limit, so the second stayed. Size retention never makes the
active segment a candidate.

The listing shows a detail: the deleted segment's file is still there, with `.deleted` added to its
name. A minute later (`file.delete.delay.ms`) it is gone, and the topic begins at 7081:

```
ubuntu@stream:~/work$ ls ~/kafka-data/node1/log/old-sales-0/*.log*
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000007081.log
/home/ubuntu/kafka-data/node1/log/old-sales-0/00000000000000014354.log
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic old-sales --from-beginning --max-messages 1 --formatter-property print.offset=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Offset:7081	{"sale": "rec-007082", "shop": "recife", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-03T05:40:00-03:00"}
Processed a total of 1 messages
```

The first message from the beginning is now offset 7081, Recife's sale `rec-007082`. **A consumer that had not read the first 7 081 sales has lost them**, and nothing
told it so: that is what retention costs, and it is why lesson 16 watches how far behind consumers
are.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 185\" role=\"img\" aria-label=\"The partition old-sales-0 as three segments in a row: the first, closed at one mebibyte, holds offsets 0 to 7080, the second, also closed at one mebibyte, 7081 to 14353, and the active segment from 14354 on, still being written. With retention.bytes set to one mebibyte, the first segment is deleted whole, and the log start offset moves from 0 to 7081. Size retention never deletes the active segment.\" data-fig=\"l3-segments\"><defs><marker id=\"l3-segments-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000000000.log</text><text x=\"130\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offsets 0 to 7080</text><text x=\"130\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">closed at 1 MiB</text><rect x=\"260\" y=\"70\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000007081.log</text><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">offsets 7081 to 14353</text><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">closed at 1 MiB</text><rect x=\"490\" y=\"70\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">00000000000000014354.log</text><text x=\"590\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">from 14354</text><text x=\"590\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">still growing</text><text x=\"130\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">deleted whole</text><text x=\"590\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">active, being written</text><line x1=\"262\" y1=\"40\" x2=\"262\" y2=\"66\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l3-segments-ah-726)\"></line><text x=\"262\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">log start offset: 0 before, 7081 after</text></svg>", "caption": "Retention removes the oldest closed segment whole; the earliest offset jumps to the next segment's base offset."}
```

Retention by time works the same way, a segment at a time: a closed segment goes once its newest
message is older than `retention.ms`. Two consequences follow from the segment being the unit. A
message can outlive its retention by up to a segment's lifetime, because it waits for its whole
segment to expire; with the defaults that is up to a week more. And a topic with a small
`retention.ms` but the default `segment.bytes` of a gibibyte keeps everything until that gibibyte
fills, unless `segment.ms` closes segments sooner.
