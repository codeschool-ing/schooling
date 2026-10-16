---
title: Partitioning: which machine holds a row
version: 1
---

**Partitioning splits one data set into parts and gives each part to one machine. The decision that
matters is the key that sends a row to its part, because that key decides which questions are cheap
to ask.** The wrong picture is a cake: cut the table into four equal slices, any way at all, and
hand them out. Four equal slices cut at random answer every question by asking all four machines.

Three words first. Each part is a **partition**; many databases call it a **shard**, and splitting
a database that way is **sharding**. The column whose value decides where a row goes is the
**partition key**. And you have met a partition already: lesson 3 saves each day of rides in a
directory named after its date, like `date=2025-09-15`, which is a data set partitioned by day.

## By range

**Range partitioning gives each partition a run of consecutive keys.** The first week of September
in one partition and the second week in the next; or stations ST01 to ST03 on one machine, ST04 to
ST06 on another. A question about a range — the rides of the second week of September — reads one
partition, or two, and skips the rest. That is why data on disk is so often partitioned by date.

The weakness is in where new data lands. Every ride that starts today has today's date, so every
write today goes to one partition while the others hold the past. And a range that happens to be
busy is busy on one machine.

## By hash

**Hash partitioning runs the key through a hash function and lets the number that comes out choose
the partition.** A hash function turns `R000001` and `R000002` into two numbers that look unrelated,
so neighbouring keys land far apart, and with many keys every partition gets about the same share.
Today's rides spread over every machine instead of piling onto one.

The price is the mirror of range's virtue. Keys that were neighbours are no longer together, so a
question about a range of them, this week's rides, has to ask every partition.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Two rows of four partitions. By range of station: partition 0 holds ST01 to ST03, partition 1 ST04 to ST06, partition 2 ST07 to ST09, partition 3 ST10 to ST12. By hash of station: partition 0 holds ST10; partition 1 ST03, ST04, ST05 and ST12; partition 2 ST01, ST07, ST09 and ST11; partition 3 ST02, ST06 and ST08. The partition holding ST02 is marked in each row.\" data-fig=\"partitioning\"><defs><marker id=\"partitioning-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">by range</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">of station</text><rect x=\"150\" y=\"30\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partition 0</text><text x=\"214.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST01 ST02 ST03</text><rect x=\"292\" y=\"30\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"356.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partition 1</text><text x=\"356.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST04 ST05 ST06</text><rect x=\"434\" y=\"30\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partition 2</text><text x=\"498.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST07 ST08 ST09</text><rect x=\"576\" y=\"30\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partition 3</text><text x=\"640.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST10 ST11 ST12</text><text x=\"20\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">by hash</text><text x=\"20\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">of station</text><rect x=\"150\" y=\"134\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"165.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partition 0</text><text x=\"214.0\" y=\"180.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST10</text><rect x=\"292\" y=\"134\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"356.0\" y=\"157.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partition 1</text><text x=\"356.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST03 ST04</text><text x=\"356.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST05 ST12</text><rect x=\"434\" y=\"134\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"157.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partition 2</text><text x=\"498.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST01 ST07</text><text x=\"498.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST09 ST11</text><rect x=\"576\" y=\"134\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"157.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partition 3</text><text x=\"640.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST02 ST06</text><text x=\"640.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST08</text><text x=\"150\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">highlighted: the partition with ST02, the hot station</text></svg>", "caption": "The same twelve stations over four partitions. By range, neighbours stay together; by hash, they scatter. Either way, the box holding ST02 holds all of its rides."}
```

| | by range | by hash |
|---|---|---|
| a question about a range of keys | reads one partition, or a few | reads every partition |
| new keys arriving in order, like today's dates | all go to one partition | spread over all of them |
| an even share per partition | only if the ranges are chosen well | close to even, given many keys |
| where you will meet it | files by date in a data lake | most distributed databases |

Many systems use both at once: files partitioned by day, and inside each day, rows spread by a hash.
Choosing the key for a real system is part of `warehouse-modeling` and `bigdata`. Here the point is
narrower: **the key you partition by is the question you made cheap**, and every other question pays
for it. The next section shows what happens when one value of that key is far busier than the rest.
