---
title: Replay: moving a group back in the log
version: 1
---

**A queue forgets what it delivered; a log does not, and that is what makes replay possible.**
Reading a message moves only the reader's position, so moving the position back makes the reader
see the same messages again. The commonest reason is a bug: the stock program miscounted returns
from Monday at nine until the fix went out on Wednesday, and the stock it wrote in between is
wrong. With the sales still in the topic, the cure is to fix the program, move its group back to
Monday at nine and let it read them again.

Two conditions come with that. **The messages must still be there**, so replay reaches back only as
far as the topic's retention, which lesson 3 set and lesson 17 prices. And **the program must be
safe to run twice over the same input**: replay is at-least-once on purpose, so a consumer that adds
to a total rather than setting it doubles everything it replays. Lesson 8 is about making a consumer
that way.

## The group must be stopped first

`kafka-consumer-groups.sh --reset-offsets` moves a group's committed positions. The consumer from
the first section is still running in the second shell, as a member of `stock`. Try it anyway:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --reset-offsets --topic sales --to-earliest --execute
```

**Refused, and rightly.** A running member holds its position in memory and commits it every
second; anything written under it would be overwritten a moment later, or worse, half of it would.
Stop the consumer with Ctrl+C. Its screen, from the start of the lag section:

```
ubuntu@stream:~/work$ python slow_consumer.py --delay 0.1
```

## Look before you move

Every reset has two modes. Without `--execute` it is a dry run, which prints where each partition
would go and changes nothing, and **it is the one to run first, every time**:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --reset-offsets --topic sales --to-earliest --dry-run
```

`--to-earliest` sends each partition to the oldest message still kept, and the group would read the
whole topic again. That is rarely what a bug calls for. **`--to-datetime` moves each partition to the
first message written at or after a moment**, which is how "from Monday at nine" is said. The moment
here is fifteen seconds after the tills started in the lag section, halfway through the 600 sales;
yours is a moment of your own clock, in the same format, and the `-03:00` is São Paulo's offset from
UTC:

```
ubuntu@stream:~/work$ kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group stock --reset-offsets --topic sales --to-datetime
```

Each partition went to the first sale written after that moment, and the group now has about half the
topic to read again. The next time `slow_consumer.py --delay 0.1` starts, it starts there.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two partitions drawn along a clock, each message placed at the time it was written. A vertical line marks the datetime given to the reset. In each partition, the group's new position is the first message written at or after that line, so the two partitions move to different offsets that belong to the same moment.\" data-fig=\"l16-reset\"><defs><marker id=\"l16-reset-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">partition 0</text><line x1=\"120\" y1=\"70\" x2=\"680\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"136.8\" cy=\"70\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"187.2\" cy=\"70\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"232.0\" cy=\"70\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"304.8\" cy=\"70\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"411.2\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"456.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"517.5999999999999\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"596.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"652.0\" cy=\"70\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"411.2\" cy=\"70\" r=\"9\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"425.2\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">new position: offset 4</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">partition 1</text><line x1=\"120\" y1=\"150\" x2=\"680\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><circle cx=\"131.2\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"159.2\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"181.6\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"209.60000000000002\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"243.2\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"271.20000000000005\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"293.6\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"332.8\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"366.4\" cy=\"150\" r=\"5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"400.0\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"428.0\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"467.2\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"489.6\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"528.8\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"562.4000000000001\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"590.4\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"624.0\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"657.6\" cy=\"150\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"400.0\" cy=\"150\" r=\"9\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"414.0\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">new position: offset 9</text><line x1=\"388.8\" y1=\"30\" x2=\"388.8\" y2=\"185\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></line><text x=\"388.8\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">--to-datetime</text><path d=\"M 120 200 L 680 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-reset-ah-8343)\"></path><text x=\"680\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">record timestamp</text></svg>", "caption": "A reset by datetime picks an offset per partition; the offsets differ, the moment is the same."}
```

**The datetime is compared with the record timestamp, not with anything inside the message.** The
sales carry `"at": "2026-03-02T09:..."`, the till's own clock, and the reset knows nothing about it:
it asked the broker for the offsets by the time each record was written. When the two clocks
disagree, as they do when a till sends a backlog, the reset goes by the broker's, and lesson 9 says
why that matters.

## The other ways to say where

| option | moves each partition to |
|---|---|
| `--to-earliest`, `--to-latest` | the oldest kept message, or the end (skip everything waiting) |
| `--to-datetime 2026-03-02T09:00:00.000` | the first message written at or after that moment |
| `--by-duration PT2H` | the same, for a moment two hours ago |
| `--shift-by -100` | 100 messages back from where it is, per partition |
| `--to-offset 1234` | exactly that offset (useful with `--topic sales:1` for one partition) |
| `--from-file plan.csv` | what a CSV says, written earlier by `--export` |

`--to-latest` deserves a warning of its own. It is the fast way out of a lag nobody can drain, and
**every message it skips is never handled**. Sometimes that is right, a live view of the shops that
only cares about now; for stock, it is a count that is wrong forever.
