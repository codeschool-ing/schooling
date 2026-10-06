---
title: The range
version: 1
---

The **range** is the largest value minus the smallest.

- Lia: 36 − 33 = **3 minutes**.
- Davi: 44 − 22 = **22 minutes**.

On these two couriers it does the job. Davi's range is more than seven times Lia's, and that matches what the dots show.

## Two values decide it

The range uses exactly two values, the extremes, and ignores everything between them. That makes it fragile in two ways.

**One unusual value controls it.** Suppose Lia had one bad day: a flat tyre, 58 minutes. Her other seven deliveries are as tight as ever, yet her range jumps from 3 to 25 minutes, now larger than Davi's. The range would call her the less dependable courier on the strength of one puncture.

**It grows with the amount of data.** The more deliveries you look at, the more chances there are to catch an unusually fast or slow one, so the range keeps growing even when nothing about the courier changes. Lia's range over eight deliveries and her range over eight hundred are not comparable numbers. That is a strange property for a measure of spread, and the next two measures do not have it.

## Where the range is still the right tool

The range answers one question perfectly: **what were the limits?** For a quality check — did any bag weigh under 4.9 kg? did any delivery take longer than an hour? — the extremes are the whole point, and the range, or simply the minimum and the maximum, is what to report.

It is also a quick sanity check on any column. Horta's twelve delivery times run from 27.5 to 61 minutes, a range of 33.5. A range of 330 would point at a typing error before any other calculation was made.

For describing how spread out the values *typically* are, though, a measure that uses all of them is needed.
