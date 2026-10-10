---
title: Idle sources
version: 1
---

**A processor reading several partitions keeps a watermark per partition and uses the lowest, so
one partition with nothing in it holds every window of every partition open.** It is the failure
that surprises people most, because it looks like nothing at all: no error, no late events, and
no results.

The lowest is the right rule, and the reason is lesson 9's last section. Each partition has its own
arrival order and there is no order between partitions. If one partition's latest sale is from
09:21 and another's is from 09:12, the second may still be about to deliver a sale from 09:11; a
watermark taken from the first would declare it late before it arrived. So the processor can only
claim that time has got as far as its slowest input has got.

`watermark.py --partitions 2` sends Recife and Olinda's sales through one partition and Natal and
Caruaru's through another, the way shops keyed by name spread over partitions:

```
ubuntu@stream:~/work$ python watermark.py --partitions 2
```

The watermark is now held by whichever partition is behind. After sale 10, Recife's 09:21:00, the
first partition has reached 09:21 but the second's latest is still Caruaru's 09:12:30, so the
watermark stays at 09:10:30 and the 09:10 window, emitted at sale 10 with one partition, is
**still open at the end**. A slow partition costs latency for everybody.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three partitions after sale 10. Partition 0, Recife and Olinda, has reached 09:21:00. Partition 1, Natal and Caruaru, has reached 09:12:30. Partition 2, João Pessoa, has nothing. The watermark is the lowest of the three minus the bound, so with partition 2 empty there is no watermark at all; leaving it out as idle gives 09:12:30 minus two minutes, 09:10:30.\" data-fig=\"l11-partitions\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partition 0: recife, olinda</text><line x1=\"220\" y1=\"40\" x2=\"640\" y2=\"40\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><line x1=\"220\" y1=\"40\" x2=\"560\" y2=\"40\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></line><circle cx=\"560\" cy=\"40\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"570\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">latest 09:21:00</text><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partition 1: natal, caruaru</text><line x1=\"220\" y1=\"80\" x2=\"640\" y2=\"80\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><line x1=\"220\" y1=\"80\" x2=\"400\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"3\"></line><circle cx=\"400\" cy=\"80\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"410\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">latest 09:12:30</text><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">partition 2: joao-pessoa</text><line x1=\"220\" y1=\"120\" x2=\"640\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"></line><text x=\"230\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing yet</text><rect x=\"20\" y=\"160\" width=\"680\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lowest of the three: none, so no watermark</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">partition 2 idle: 09:12:30 minus 2 min = 09:10:30</text></svg>", "caption": "The slowest partition sets the watermark. An empty one sets none, until it is declared idle."}
```

## A partition with nothing

Ponto Final has five shops and these sales come from four of them. With three partitions, João
Pessoa's partition has nothing at all:

```
ubuntu@stream:~/work$ python watermark.py --partitions 3
```

**The watermark never exists, and no window is ever emitted.** Every sale is counted, nothing is
late, and the output is empty, for as long as João Pessoa sells nothing, which on a quiet Monday
could be all morning. A shop that closes for a week stalls the whole chain for a week. In a real
topic the same happens with a partition that no key hashes to, which lesson 3's section on
choosing partitions makes likely with few keys and many partitions.

## Declaring a source idle

The way out is to let a partition that has been quiet for a while drop out of the minimum, and
rejoin when it sends something. Flink calls it `withIdleness(Duration)`, measured on the
processor's clock. The program has no clock, so `--idle` counts sales instead: a partition that
has had nothing during the last three sales is left out:

```
ubuntu@stream:~/work$ python watermark.py --partitions 3 --idle 3
```

From sale 3 on, João Pessoa's partition is idle and the watermark comes from the other two. The
first two windows are emitted at sale 7 and sale 8 is dropped, as with two partitions.

**Idleness is a bet in the other direction.** A partition declared idle that then delivers an old
sale delivers a late one, and the watermark, which only moves forward, does not wait for it. The
timeout should be longer than the normal quiet spells of the quietest source, which is one more
distribution worth measuring. Spark sidesteps the question by keeping one watermark per query from
the latest event time across all its input, which never stalls and drops more events when
partitions run unevenly; Kafka Streams keeps a stream time per task from the highest timestamp it
has seen. Neither is free, and lesson 13 compares them.
