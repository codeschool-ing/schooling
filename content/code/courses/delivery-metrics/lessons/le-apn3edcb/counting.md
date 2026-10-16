---
title: Counting instead of weighing
version: 1
---

A date for a set of work, a release or a quarter's commitments, depends on how much the team gets through per week. That can be measured in points, by summing them, or in items, by counting. **Save the program below as `weekly.py`** to compare the two on the Billing team's weeks since the new rules.

```schooling-example
{
  "language": "python",
  "file": "weekly.py",
  "parts": [
    {
      "code": "\"\"\"weekly.py: what the team finished each week, counted in items and in points.\"\"\"\nimport csv\nimport statistics\nfrom datetime import date, timedelta\n\nitems = [i for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]]\nmonday = date(2026, 8, 3)\ncounts, points = [], []\nprint(\"week of      items  points\")\nwhile monday + timedelta(days=6) <= date(2026, 9, 30):\n    week = [i for i in items\n            if monday <= date.fromisoformat(i[\"merged\"][:10]) < monday + timedelta(days=7)]\n    counts.append(len(week))\n    points.append(sum(int(i[\"points\"]) for i in week))\n    print(f\"{monday}  {counts[-1]:5}  {points[-1]:6}\")\n    monday += timedelta(days=7)\n",
      "note": "**Every whole week since the new rules**, Monday to Sunday: how many items merged, and how many points they carried between them."
    },
    {
      "code": "\nfor name, values in ((\"items\", counts), (\"points\", points)):\n    spread = statistics.stdev(values) / statistics.mean(values)\n    print(f\"{name:6} mean {statistics.mean(values):5.1f} a week, varies by {spread:.0%} week to week\")\n",
      "note": "**How much each measure jumps around**: the standard deviation as a share of the mean, the *coefficient of variation*. A measure that is steadier from week to week is the better basis for a forecast."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 weekly.py
week of      items  points
2026-08-03     13      23
2026-08-10      7      25
2026-08-17     10      30
2026-08-24      8      17
2026-08-31      8      25
2026-09-07      6      13
2026-09-14      6      13
2026-09-21      6      21
items  mean   8.0 a week, varies by 31% week to week
points mean  20.9 a week, varies by 29% week to week
```

The two series are **equally noisy**: items vary by 31% from week to week and points by 29%. If points measured the work more faithfully than a count, the points line would be steadier, because big items and small items would even out. It is not. **A forecast built from points is no more precise than one built from a count, and the count needs no meeting.** The week of 10 August is a fair illustration: the fewest items of August, seven, and among the most points, 25. Neither number predicted the week after.

The first week, 13 items, is the old system draining out, which lesson 1 met. A forecast would leave the first weeks after a change of rules out of its history; lesson 10 says how to choose the window.

## Making counting work: right-size the items

Counting has one requirement: an item has to be **small enough that its size does not matter much**. The usual test is a single question asked when an item is about to be started, and it replaces the estimation meeting:

> **"Can we finish this within our 85th percentile?"**

For the Billing team in September that is eight days. If the answer is yes, the item is started as it is. If the answer is no, or "we are not sure", the item is split into pieces that each pass the test. That is still estimation, but of the cheapest kind: a yes or no against a number the team already knows, made by the people about to do the work.

Right-sizing also improves everything else in the course. Smaller items wait less, block less, and make smaller deployments, which is the batch-size argument of lessons 5 and 7 arriving from a different direction. The eight-point items in the previous section were the slowest group under both sets of rules, and splitting them would have shortened the tail.

## What counting does not do

Counting assumes the future's items look like the past's. A team about to start a kind of work it has never done, a new integration, a migration, has no history for it, and a count of past items says little. That is one of the cases the last section of this lesson keeps estimation for.
