---
title: Compaction, the latest value for every key
version: 1
---

**A compacted topic keeps, for every key, at least the last message written with that key, and is
allowed to throw away the older ones.** Retention by time or size forgets the past wholesale;
compaction forgets only what has been overwritten. It is lesson 2's table made on disk: a stream of
changes, folded down to the latest value per key, and still readable as a log.

That suits a topic whose messages are **state rather than events**: the current stock of each book,
the current address of each customer. Nobody needs the stock as it was on Tuesday, but a new reader
needs every book's current stock, and a compacted topic gives it that by reading from offset 0. It
does not suit `sales`, where every message is a separate fact and the old ones are not superseded by
the new.

## Watching it work

The cleaner, the broker thread that compacts, is cautious by default: it leaves a log alone until
half of it is overwritten values, and it never touches the active segment. So this topic closes
segments after five seconds and gets cleaned as soon as 1% of it is dirty, which a real topic would
not do. Make it, and send the stock of three books, changing, with `keys.py` from earlier in this
lesson:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic stock --partitions 1 --config cleanup.policy=compact --config segment.ms=5000 --config min.cleanable.dirty.ratio=0.01
Created topic stock.
ubuntu@stream:~/work$ python keys.py stock bk-01=4 bk-02=7 bk-03=2 bk-01=3 bk-02=6 bk-01=2 bk-03=-
bk-01        partition 0  offset 0
bk-02        partition 0  offset 1
bk-03        partition 0  offset 2
bk-01        partition 0  offset 3
bk-02        partition 0  offset 4
bk-01        partition 0  offset 5
bk-03        partition 0  offset 6
```

The last pair, `bk-03=-`, is a message with the key `bk-03` and no value at all, which the next
section explains. Seven messages, offsets 0 to 6, all in the active segment.

Wait more than five seconds, so that segment is old enough to close, and send one more message.
The segment is closed when the next message arrives, so this one starts a new active segment:

```
ubuntu@stream:~/work$ python keys.py stock bk-04=9
bk-04        partition 0  offset 7
```

Give the cleaner a few seconds; when it has nothing to do it looks again every fifteen
(`log.cleaner.backoff.ms`). Then read the topic from the beginning:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic stock --from-beginning --max-messages 4 --formatter-property print.offset=true --formatter-property print.key=true
The consumer rebalance protocol (KIP-848) is production-ready! Set group.protocol=consumer to try it out. See https://kafka.apache.org/documentation/#consumer_rebalance_protocol
Offset:4	bk-02	6
Offset:5	bk-01	2
Offset:6	bk-03	null
Offset:7	bk-04	9
Processed a total of 4 messages
```

Four messages are left, and they are the last value of each key: `bk-02` is 6, `bk-01` is 2,
`bk-03` has its tombstone, printed as `null`, and `bk-04` is 9, still alone in the active segment.
`bk-01=4`, `bk-01=3`, `bk-02=7` and `bk-03=2` are gone, **and the survivors kept their offsets**:
the topic now starts at offset 4, and offsets 0 to 3 are missing for good.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"The stock topic before and after compaction. Before: eight messages at offsets 0 to 7, bk-01 = 4, bk-02 = 7, bk-03 = 2, bk-01 = 3, bk-02 = 6, bk-01 = 2, a tombstone for bk-03, and bk-04 = 9 in the active segment. After: only offsets 4, 5, 6 and 7 remain, the last value of each key and the tombstone, keeping their original offsets, so offsets 0 to 3 are a hole.\" data-fig=\"l3-compaction\"><text x=\"20\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">before</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">after</text><text x=\"56\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">offset</text><rect x=\"90\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"125\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-01=4</text><rect x=\"90\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"125\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><rect x=\"168\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"203\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"203\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-02=7</text><rect x=\"168\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"203\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><rect x=\"246\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"281\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"281\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-03=2</text><rect x=\"246\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"281\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><rect x=\"324\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"359\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"359\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-01=3</text><rect x=\"324\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"359\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><rect x=\"402\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"437\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-02=6</text><rect x=\"402\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"437\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"437\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-02=6</text><rect x=\"480\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"515\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"515\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-01=2</text><rect x=\"480\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"515\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"515\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-01=2</text><rect x=\"558\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"593\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"593\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">bk-03=null</text><rect x=\"558\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"593\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"593\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">bk-03=null</text><rect x=\"636\" y=\"40\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"671\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"671\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-04=9</text><rect x=\"636\" y=\"145\" width=\"70\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"671\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"671\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">bk-04=9</text><line x1=\"632\" y1=\"30\" x2=\"632\" y2=\"205\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"359.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">closed segment</text><text x=\"671\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">active segment</text><text x=\"593\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">tombstone</text></svg>", "caption": "Compaction keeps the last message for each key, at the offset it was written; the active segment is left alone."}
```

## Tombstones

A message with a key and no value is a **tombstone**: it says *this key is deleted*. Compaction
keeps the tombstone itself for `delete.retention.ms`, a day by default, so that a reader who is
part way through the log sees the deletion instead of missing it, and then removes the tombstone
too. After that, the key is simply absent, as if it had never been written.

Two things follow that people get wrong. **Compaction is not immediate**: until the cleaner runs, a
reader from offset 0 sees every old value, so a reader of a compacted topic still has to fold, and
take the last value per key as `balance.py` did. And **compaction keeps offsets**: the surviving
messages keep the offsets they were written at, so a compacted partition has holes in its offsets,
and a reader must not assume offset *n* + 1 follows *n*. Lesson 14 meets compacted topics again,
where a database's rows arrive as messages keyed by primary key and a deleted row becomes a
tombstone.
