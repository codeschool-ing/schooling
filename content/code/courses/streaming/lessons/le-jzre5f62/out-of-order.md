---
title: Out of order, and by how much
version: 1
---

**A stream arrives in arrival order. Event order is something you reconstruct, if you need it,
and only up to a point.** The common assumption runs the other way: that records come in the order
things happened, apart from the odd glitch. Measured, the glitch turns out to be a sizeable share
of the data, with a shape that matters more than its size.

Out of order has a precise meaning here. A sale is out of order when, by the time it arrives, a
sale that happened **later** has already been seen. How far out of order it is, is the distance
between its own event time and the latest event time seen before it. That second number is worth
remembering, because lesson 11 builds the watermark out of it.

## Measuring it

The `late` topic has one partition, so its records come back in exactly the order they arrived.
Three tools, chained, do the measuring. The console consumer prints the sales, `jq` turns each
`at` into seconds since 1970, and `awk` keeps the latest event time it has seen (`seen`) and, for
every sale, how far behind it that sale is:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic late --from-beginning --max-messages 360 2>/dev/null \
  | jq -r '.at[:19] + "Z" | fromdate' \
  | awk '$1 > seen { seen = $1 } { behind = seen - $1 }
         behind > 0 { late++ } behind > 60 { minute++ } behind > 3600 { hour++ }
         END { print NR, "sales,", late, "out of order:", minute, "by over a minute,", hour, "by over an hour" }'
360 sales, 68 out of order: 49 by over a minute, 29 by over an hour
```

Two details make the `jq` step honest. Every `at` in these sales carries the same offset, `-03:00`,
so the first nineteen characters compare correctly as if they were UTC, and `fromdate` only reads
UTC. Two sales an offset apart would need the offset applied, which is a step a real pipeline
cannot skip.

**68 of 360 sales arrived out of order: almost one in five.** That is not the 38 from Natal. Thirty
of them were a few seconds to a minute and a half behind, ordinary sales from every shop that
happened to take 40 or 95 seconds on the way while a later sale from another shop took one.
Nobody would call those late. They are what a network does.

## Two populations

Sorted, the 68 distances fall into two groups with very little between them:

| behind by | sales | what they are |
|---|---|---|
| up to 92 seconds | 30 | slow deliveries, from every shop |
| 14 minutes to 3 hours 23 minutes | 38 | Natal's held sales, all arriving at 14:00 |

The two groups need different treatment, and most of the design of a stream processor is deciding
which treatment each gets. A wait of two minutes would put the first group back in order at the
cost of every result arriving two minutes late. No wait anybody would accept would put the second
group back in order: to wait for Natal is to hold every result of the day until four hours after
the fact, which is the nightly batch again with extra steps.

**So "how out of order is my stream?" has no single answer.** It has a distribution, and the
question that matters is where in it to draw a line: the sales behind the line are handled as if in
order, and the ones beyond it are handled as late. Lesson 11 draws that line and calls it the
bound of a watermark; its section on choosing the bound measures this distribution from data, as
you just did.

## What one partition hides

All of this was measured on one partition, where arrival order is a single, readable thing. A topic
with three partitions has three arrival orders, one each, and no order at all between them: lesson 3
shows that a consumer reading several partitions interleaves them however the fetches happen to
come back. Out of order across partitions is therefore the normal state, not a fault, and it is why
a processor that cares about event time keeps its sense of "how far has time got" **per
partition**, which lesson 11 comes back to.
