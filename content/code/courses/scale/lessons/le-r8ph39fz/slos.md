---
title: Objectives, and the budget for failing them
version: 1
---

Metrics answer "what is the box office doing?". Running it needs a second question answered in
advance: **what is it supposed to do?** Without an answer, every graph is a matter of opinion, and
every alert is either too noisy or too late.

Three terms, from Google's site reliability engineering practice:

- An **SLI**, service level indicator, is a measurement of the service as users experience it,
  written as a ratio: good events divided by all events.
- An **SLO**, service level objective, is the target for an SLI over a window: 99.9% of sales
  answered successfully within 250 ms, over 30 days.
- The **error budget** is what the objective allows to fail: 0.1% of sales over the window.

## The box office's SLI, from its own histogram

Section 07 said to put a bucket boundary at the value the objective names. The box office has one at
0.25 s, so the fraction of sales answered within 250 ms is the count of that bucket divided by the
count of all sales, both as rates. Here it is during thirty seconds of sales at 16 workers:

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum(rate(tickets_request_seconds_bucket{route="/events/{id}/tickets", le="0.25"}[30s])) / sum(rate(tickets_request_seconds_count{route="/events/{id}/tickets"}[30s]))'
{} => 1 @[1791612667.816]
```

**1**, every sale within 250 ms in that window: the objective was met with all of its budget left.
The same query over thirty days, with a slow day in it, is how the SLO is checked, and its
complement is how much of the budget has been spent.

## What the budget is for

The budget turns reliability into a quantity that can be spent on purpose:

| over 30 days | 99% | 99.9% | 99.99% |
|---|---|---|---|
| sales that may fail, at 1 million sales | 10 000 | 1 000 | 100 |
| complete outage it allows | 7 h 12 min | 43 min | 4 min 19 s |

- **A budget unspent is room to move faster**: deploys, migrations like lesson 6's, experiments.
- **A budget spent is a reason to slow down** and spend the next weeks on reliability rather than
  features.
- **Alert on the budget's burn rate, not on every blip.** An alert that fires when the budget is
  being spent fast enough to run out within hours is worth waking up for; one that fires on a single
  slow request is not.

**The objective should be lower than what the system can do.** Nobody notices the difference
between 99.99% and 100%, and promising 100% leaves no budget for any change at all. The right SLO is
the one below which users start to complain, measured rather than guessed, and lesson 11 is about
keeping the box office above it as the load grows.
