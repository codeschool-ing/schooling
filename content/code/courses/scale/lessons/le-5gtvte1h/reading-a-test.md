---
title: Reading a test
version: 1
---

A load test produces a few numbers on the generator's side, and the system produces thousands on
its own. The test result says **whether** the system met its targets; only the system says **why**,
and a test that is not read alongside the system's own telemetry is half a test.

During every run, watch at least:

- **The RED metrics of lesson 7**, from Prometheus: the rate the box office *says* it served, its
  errors by status, and its latency histogram. When they disagree with the generator, one of the
  two is lying, and finding out which is usually the most useful thing the test does. In section 06,
  the generator counted 1,547 failures that the box office never saw: they were in nginx.
- **Saturation, the S of USE**: CPU of each copy, the in-flight gauge against the slots, database
  connections, the breaker's gauge. The knee of section 06 is the moment one of these reaches its
  limit, and knowing which one is knowing what to buy.
- **The traces of lesson 8**: one slow sale from the run, opened in Jaeger, says where its time
  went, which no percentile can.
- **The generator itself**: its CPU, and k6's *never sent*. A generator on the same machine as the
  system, as in this lab, takes CPU from it. In a real test the generator runs elsewhere, and big
  tests run several generators at once.

## The traps

- **Averages.** Every number in this course has been a percentile, because a mean hides the slow
  tail that the buyers feel. Section 06's median of 2.4 ms is the reminder that even a percentile
  needs its error count beside it.
- **Too short.** A fifteen-second run finds the knee; it does not find a pool that leaks one
  connection a minute. That is the soak test.
- **Unrealistic data.** Fifty shows and random buyers make an even load. A real on-sale is one show,
  one hot row, lesson 1's limit, and a test that spreads its sales across fifty shows is testing a
  different system.
- **Cache warmth.** The first run after a restart measures the warm-up, as section 04's 99th
  percentile did. Run once to warm, or report the start apart.
