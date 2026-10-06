---
title: Percentiles
version: 1
---

The median is the value with half the data below it. Generalise that, and you get the **percentiles**: the 90th percentile is the value with 90% of the data at or below it, the 10th percentile the value with 10% at or below it, and so on.

## A promise written as a percentile

Percentiles answer a question the mean cannot: **how bad do things get for most people?** That is why service promises are written with them.

Take Horta's twelve delivery times. Ten of the twelve took 44 minutes or less. So "five out of six deliveries arrive within 44 minutes" is true of this data, and it is a much more useful promise than "the mean is 38.96 minutes", which says nothing about the slow ones. The spreadsheet's 90th percentile of the twelve is 51.65 minutes: it would let Horta say "nine deliveries in ten arrive within about 52 minutes".

Promises like these turn up in every service business. A call centre promises to answer 80% of calls within 20 seconds; a web team promises that 99% of page loads finish within one second. In each case the promise is a percentile, because a customer remembers the slow cases, and only a high percentile describes those.

## Computing one

With the values sorted, the *p*th percentile sits at position *p* × (*n* − 1) + 1, counting from 1 — the rule a spreadsheet's `PERCENTILE.INC` uses. When that position falls between two values, the percentile lies between them, in proportion.

For the 90th percentile of the twelve delivery times: 0.9 × 11 + 1 = 10.9. The 10th sorted value is 44.0 and the 11th is 52.5, so the percentile is 44.0 + 0.9 × (52.5 − 44.0) = **51.65**.

```localised
=PERCENTILE.INC(A2:A13, 0.9)      51.65
```

## Percentiles need enough data

With twelve values, the 90th percentile is an interpolation between two of them, and the 99th would be almost the maximum. High percentiles need a lot of data to be stable: a promise about 99% of deliveries is only credible when it rests on hundreds of them. With few values, report the percentiles the data can support and say how many values there were.

The three percentiles that cut the data into quarters have names of their own, and they are the subject of the next section.
