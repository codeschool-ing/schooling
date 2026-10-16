---
title: Committing an offset, and when it happens
version: 1
---

**A commit records, for a group and a partition, the offset the group should read next.** It is the
group's place in the log, the same thing `minilog.py`'s place files held in lesson 2, and it is the
only thing a consumer that restarts has to go on. **What matters is when a commit happens, relative
to the work**: a commit says "everything before this is done", and if it is not
true at the moment of a crash, the restart either repeats work or skips it.

Kafka keeps commits in a topic of its own, `__consumer_offsets`:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic __consumer_offsets | head -1
Topic: __consumer_offsets	TopicId: L73rMdVGSxKa6-xjwL1JZw	PartitionCount: 50	ReplicationFactor: 1	Configs: compression.type=producer,min.insync.replicas=1,cleanup.policy=compact,segment.bytes=104857600
```

Fifty partitions, and `cleanup.policy=compact`: each group's latest commit for each partition is the
value for a key, and lesson 3's compaction keeps only the latest. A commit is a message like any
other.

## Automatic commits

By default the client commits for you. **`enable.auto.commit` is on, and every five seconds**
(`auto.commit.interval.ms`) the client commits the offsets of the messages `poll` has returned so
far. Five seconds is a window, and a crash inside it shows what the window means. Start a consumer
in a new group, `auto`, and about four seconds later kill it from another shell, with no chance to
clean up, as a power cut would: `kill -9 $(pgrep -f 'consumer.py x')`.

```
ubuntu@stream:~/work$ python consumer.py x --group auto
x: assigned [0, 1, 2]
x: partition 2 offset 0 rec-000005
x: partition 2 offset 1 rec-000010
x: partition 2 offset 2 rec-000005
x: partition 2 offset 3 rec-000010
x: partition 1 offset 0 car-000002
x: partition 1 offset 1 nat-000003
x: partition 1 offset 2 car-000007
x: partition 1 offset 3 nat-000008
x: partition 1 offset 4 car-000002
x: partition 1 offset 5 nat-000003
x: partition 1 offset 6 car-000007
x: partition 1 offset 7 nat-000008
x: partition 0 offset 0 oli-000001
x: partition 0 offset 1 joa-000004
x: partition 0 offset 2 oli-000006
x: partition 0 offset 3 joa-000009
x: partition 0 offset 4 oli-000001
x: partition 0 offset 5 joa-000004
x: partition 0 offset 6 oli-000006
x: partition 0 offset 7 joa-000009
Killed
```

`x` read all twenty sales in the topic and printed them, and the shell printed `Killed`. Now ask
what the group committed:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group auto

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                  HOST            CLIENT-ID
auto            sales           0          -               8               -               rdkafka-9cbc0880-3e59-41b7-b81a-a1cebd910f61 /127.0.0.1      rdkafka
auto            sales           1          -               8               -               rdkafka-9cbc0880-3e59-41b7-b81a-a1cebd910f61 /127.0.0.1      rdkafka
auto            sales           2          -               4               -               rdkafka-9cbc0880-3e59-41b7-b81a-a1cebd910f61 /127.0.0.1      rdkafka
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
y: assigned [0, 1, 2]
y: partition 2 offset 0 rec-000005
y: partition 2 offset 1 rec-000010
y: partition 2 offset 2 rec-000005
y: partition 2 offset 3 rec-000010
y: partition 1 offset 0 car-000002
y: partition 1 offset 1 nat-000003
y: partition 1 offset 2 car-000007
y: partition 1 offset 3 nat-000008
y: partition 1 offset 4 car-000002
y: partition 1 offset 5 nat-000003
y: partition 1 offset 6 car-000007
y: partition 1 offset 7 nat-000008
y: partition 0 offset 0 oli-000001
y: partition 0 offset 1 joa-000004
y: partition 0 offset 2 oli-000006
y: partition 0 offset 3 joa-000009
y: partition 0 offset 4 oli-000001
y: partition 0 offset 5 joa-000004
y: partition 0 offset 6 oli-000006
y: partition 0 offset 7 joa-000009
Killed
```

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group manual

GROUP           TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                  HOST            CLIENT-ID
manual          sales           0          8               8               0               rdkafka-fa239717-d289-4555-9d36-491690cb0ae2 /127.0.0.1      rdkafka
manual          sales           1          8               8               0               rdkafka-fa239717-d289-4555-9d36-491690cb0ae2 /127.0.0.1      rdkafka
manual          sales           2          4               4               0               rdkafka-fa239717-d289-4555-9d36-491690cb0ae2 /127.0.0.1      rdkafka
```

Committed 8, 8 and 4: everything `y` printed is recorded, and a restart would read nothing twice.
Committing after every message costs a round trip to the broker per message, which is why real
consumers commit after a batch instead. Then a crash repeats at most one batch.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"One partition's messages at offsets 0 to 9, read by a consumer that has processed offsets 0 to 6. The last commit says offset 4. A crash now means a restart reads from 4, so offsets 4, 5 and 6 are processed twice. With a commit after every message, the commit would say 7, the next offset to read, and nothing would be repeated.\" data-fig=\"l4-commit\"><defs><marker id=\"l4-commit-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l4-commit-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"60\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"87.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0</text><rect x=\"120\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"147.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1</text><rect x=\"180\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"207.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text><rect x=\"240\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"267.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">3</text><rect x=\"300\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"327.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">4</text><rect x=\"360\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"387.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">5</text><rect x=\"420\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"447.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">6</text><rect x=\"480\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><rect x=\"540\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"567.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8</text><rect x=\"600\" y=\"80\" width=\"54\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"627.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">9</text><line x1=\"297\" y1=\"40\" x2=\"297\" y2=\"76\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l4-commit-ah-726)\"></line><text x=\"297\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">last commit</text><line x1=\"477\" y1=\"40\" x2=\"477\" y2=\"76\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l4-commit-ah-83)\"></line><text x=\"477\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">crash</text><path d=\"M 60 128 L 60 136 L 474 136 L 474 128\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"270.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">processed so far</text><path d=\"M 300 165 L 300 173 L 474 173 L 474 165\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"390.0\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">read again after a restart</text></svg>", "caption": "Whatever lies between the last commit and the crash is read again."}
```

Neither choice removes the problem; each moves it. Committing **after** the work, as `--manual`
does, means a crash between the work and the commit repeats that message: **at least once**.
Committing **before** the work means a crash between the commit and the work loses it: **at most
once**. Lesson 7 makes both crash on purpose and counts the damage, and lesson 8 makes repeated work
harmless, which is the usual way out.
