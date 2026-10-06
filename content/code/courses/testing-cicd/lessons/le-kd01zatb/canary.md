---
title: A small share of real traffic first
version: 1
---

A **canary** release sends a small share of production's traffic to the new version, compares it
with the rest, and widens the share only while the comparison stays clean. The name comes from the
birds miners carried underground: a bird in trouble warned them before the air harmed anybody else.

The lab needs nothing new for it. The same router, the same two sides: the weights are simply not
all-or-nothing. Green still runs 1.6.0, the release with the error. This time it gets one request
in ten:

```
ana@laptop:~/shipquote$ sed -i 's/"blue": 100, "green": 0/"blue": 90, "green": 10/' ~/envs/routes.json && cat ~/envs/routes.json
{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 90, "green": 10}}
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 1000
backend    requests errors    rate
blue            898      0    0.0%
green           102      2    2.0%
```

Of a thousand requests, blue served 898 and green 102. Blue had no errors; green had 2. The bug that
reached every customer in the blue-green switch here reached about one customer in ten, and only one
of those in twenty: **two failed requests instead of seventy-seven**. That smaller damage is what a
canary sells.

## Steps

A canary rarely jumps from 10% to everything. It moves through steps, for example 5%, 25%, 50% and
100%, and at each step it waits long enough to judge before it goes on. Two things change at each
step:

- the share of customers who would meet a bug grows, so a mistake costs more the later it is found;
- the amount of evidence grows too, so a rare bug becomes visible.

The first steps are small because nothing is known yet. The later steps are bigger because a release
that survived the earlier ones has earned some trust.

## What a canary needs that blue-green did not

- **A way to tell the two sides apart in the measurements.** Here the router writes `X-Served-By` on
  every answer and `load.py` counts by it. In production that is a label on every metric, saying
  which version produced it.
- **Traffic.** A canary at 10% of a quiet service is a canary that sees nothing for an hour. The
  next two sections are about what to measure, and how much is enough.
