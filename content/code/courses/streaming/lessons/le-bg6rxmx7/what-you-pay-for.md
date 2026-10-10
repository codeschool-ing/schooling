---
title: What a stream is billed for
version: 1
---

**The cost of a batch follows the work; the cost of a stream follows the clock.** A nightly job
that runs for twenty minutes pays for twenty minutes of a machine, and a quiet day costs less than a
busy one. A stream pays for its brokers and its consumers every hour of every day, because they have
to be there when the next sale arrives, and nobody knows when that is. Most of what is surprising
about a streaming bill comes from forgetting that difference.

The bill has three parts, and each one grows with a different thing.

## Compute: always on

The brokers, the consumers, the processing engines of lessons 12 and 13, and whatever watches them.
Each is a process with memory reserved and a machine under it, whether a sale arrives in the next
second or in the next eight hours. **Compute is sized for the peak and paid for at the trough.** A
consumer group sized so that Saturday morning drains in minutes is mostly idle on Tuesday night, and
it costs the same.

## Storage: throughput times retention times copies

A broker keeps every message until retention removes it, and keeps it on every replica. So the disk
a topic needs is four numbers multiplied:

| factor | what sets it | for Ponto Final's sales, later in this lesson |
|---|---|---|
| messages a day | the business | sales rung up across five shops |
| bytes per message, on disk | the message and its compression | measured, not guessed |
| days kept | `retention.ms` | how far back a replay has to reach |
| copies | the replication factor | three, as in lesson 5 |

**None of the four is small by accident, and each is a decision.** Retention is the one people set
once and forget. A week is enough for most replays; a year of sales kept in Kafka because nobody
changed the default is a disk bill for an archive nobody reads, which belongs in object storage or
in the warehouse.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 140\" role=\"img\" aria-label=\"Four boxes multiplied together give the disk a topic needs: messages a day, bytes per message on disk, days kept, and copies. Under each box, what sets it: the business, the message and its compression, retention.ms, and the replication factor.\" data-fig=\"l17-formula\"><rect x=\"20\" y=\"45\" width=\"116\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"78.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">messages a day</text><text x=\"78.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the business</text><text x=\"149\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper-dim)\">×</text><rect x=\"162\" y=\"45\" width=\"116\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bytes per message</text><text x=\"220.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">message + compression</text><text x=\"291\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper-dim)\">×</text><rect x=\"304\" y=\"45\" width=\"116\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">days kept</text><text x=\"362.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">retention.ms</text><text x=\"433\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper-dim)\">×</text><rect x=\"446\" y=\"45\" width=\"116\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"504.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">copies</text><text x=\"504.0\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replication factor</text><text x=\"582\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" fill=\"var(--paper-dim)\">=</text><rect x=\"598\" y=\"45\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">disk needed</text></svg>", "caption": "Storage is four factors multiplied, and each one is somebody's decision."}
```

## Network: in, out, and between

Every byte written arrives once from a producer, travels to every follower replica, and leaves once
for every consumer group that reads it. A topic written at one megabyte a second, with three replicas
and four groups reading it, moves one megabyte in, two between brokers and four out: **seven times
what was written**.

Inside one data centre that traffic is usually not billed. **Across availability zones it usually
is**, in both directions, and a cluster spread over three zones for safety, which lesson 5 argues
for, sends two of every three replica copies across a zone boundary. Consumers that read from a leader
in another zone add to it. Kafka can let a consumer read from a follower in its own zone
(`client.rack` on the consumer, a `replica.selector.class` on the brokers), and that setting exists
for this bill alone.

## What it does not include

The people. A stream is operated around the clock, as lesson 16 showed: lag to watch, dead letters
to read, partitions to rebalance, upgrades that cannot stop the world. A team that can do that is a
cost that rarely appears in the comparison with a nightly job, and it is often the largest one.
