---
title: From visitors to a date
version: 1
---

A sample size becomes a duration through the traffic, and a duration becomes a test plan through
the calendar.

```schooling-example
{"language": "python", "file": "duration.py", "parts": [{"code": "from math import ceil\n\nper_group = 18739\nvisitors_per_day = 2400\nshare_in_test = 1.0", "note": "The textbook figure from two sections back, and Panela's traffic to the checkout. `share_in_test` is the share of that traffic sent into the experiment."}, {"code": "days = ceil(2 * per_group / (visitors_per_day * share_in_test))\nweeks = ceil(days / 7)\nprint(f\"{2 * per_group:,} visitors in total at {visitors_per_day:,} a day: {days} days\")\nprint(f\"rounded up to whole weeks: {weeks} weeks, {weeks * 7} days\")", "note": "Two groups' worth of visitors, divided by the daily traffic, then rounded up to whole weeks."}, {"code": "for share in (0.5, 0.2):\n    days = ceil(2 * per_group / (visitors_per_day * share))\n    print(f\"with only {share:.0%} of the traffic in the test: {days} days, {ceil(days / 7)} weeks\")", "note": "The same test with part of the traffic, as when several tests share a site."}], "output": "37,478 visitors in total at 2,400 a day: 16 days\nrounded up to whole weeks: 3 weeks, 21 days\nwith only 50% of the traffic in the test: 32 days, 5 weeks\nwith only 20% of the traffic in the test: 79 days, 12 weeks"}
```

**16 days of traffic, and the test runs for 3 weeks.** The rounding is not tidiness. Lesson 1
showed that Panela's Mondays carry about a third more orders than its Saturdays, and the visitors of
different weekdays may convert differently too. A test that ran from a Monday to the following
Tuesday would hold two Mondays and one of every other day, and its result would lean towards
whatever Monday visitors do. **Whole weeks give every weekday the same weight.** Twenty-one days
is exactly the length of Panela's test in `experiment.csv`, which lesson 10 reads.

Two more rules set the edges of the calendar.

- **At least one full week, even when the arithmetic says less.** A test that reaches its sample in
  three days has seen three weekdays and no weekend.
- **Not much longer than needed.** Long tests collect problems: visitors clear their cookies and
  come back as new ones, other changes ship on the same pages, and a holiday arrives. Planning
  around Carnival or Black Friday, or deliberately not, is part of choosing the start date.

## Sharing the traffic

Sending only part of the traffic into a test makes it slower in proportion: half the traffic, about
twice as long, 32 days here; a fifth, 79 days. Teams do it to limit the risk of a bad
treatment or to run several tests at once. When the result is too slow to be useful, the levers are
the ones from the previous section: a bigger change, a more sensitive metric, or a test of only the
visitors the change can affect, such as only those who reach the checkout.
