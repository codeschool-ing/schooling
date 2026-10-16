---
title: Four questions, four tests
version: 1
---

Lesson 11 ended with a plan: four copies, 24 slots each, for 1,000 reads and 100 sales a second. A
plan is a set of measurements of one copy, multiplied, plus assumptions about everything the
multiplication left out. This lesson tests it the only way that tests anything: **by sending the
load and watching what happens**.

"Load testing" is used for several different tests, and each answers a different question:

| test | what it sends | what it answers |
|---|---|---|
| **load test** | the expected peak, for a while | does the plan hold at the load we expect? |
| **stress test** | more and more, until something breaks | where is the limit, and what breaks first? |
| **spike test** | a sudden jump from quiet to peak | does it survive the first ten seconds of an on-sale? |
| **soak test** | ordinary load, for hours | does anything leak, fill up or slow down over time? |

The first two are this lesson. A spike test is a stress test with a shape: the first minute of an
on-sale is a spike, and caches that are cold, copies still starting and connection pools still
filling are what it finds. A soak test finds what accumulates: memory that grows, a disk that fills
with logs, a table that bloats without vacuum, lesson 6's subject. Both use the same tools as the
other two.

Every test needs three things written down **before** it runs: the load, what is measured, and
what counts as passing. A test without a pass mark produces numbers that everybody reads as good
news.
