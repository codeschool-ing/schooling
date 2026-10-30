---
title: What leaving costs
version: 1
---

The cost of leaving a provider is usually discussed as a feeling. **It can be estimated, and the
estimate has three parts: moving the data, rewriting what touches Google directly, and running two
systems while the move happens.** Only the first has a price list; the other two are measured in
people's time, which makes them larger and less visible.

## Moving the data

Data leaving Google Cloud for the internet is billed per GiB, in tiers that get cheaper as the
month's volume grows. On the network pricing page on 30 October 2026, for Iowa's Premium Tier to
North America: the first GiB of the month is free, then 0.12 per GiB up to 1 TiB, 0.11 up to
10 TiB, and 0.08 beyond. A short program prices a move of any size; save it as `~/gcp/egress.py`:

```python
# egress.py
import sys

# Premium Tier, Iowa to North America, per GiB in a month (30 October 2026)
TIERS = [(1, 0.0), (1024, 0.12), (10240, 0.11), (float('inf'), 0.08)]


def cost(gib):
    total, below = 0.0, 0
    for top, price in TIERS:
        if gib > below:
            total += (min(gib, top) - below) * price
        below = top
    return total


for arg in sys.argv[1:]:
    gib = float(arg) * 1024
    print(f'{arg:>6} TiB  {cost(gib):>10.2f} USD')
```

The tiers are a list of where each one stops and what it charges, and `cost` walks them, charging
each slice of the volume at its own rate. Three sizes:

```
ana@laptop:~/gcp$ python3 egress.py 1 5 50
     1 TiB      122.76 USD
     5 TiB      573.32 USD
    50 TiB     4413.32 USD
```

The shop's photos, a few hundred GiB, would cost a few tens of dollars to move; a company with
50 TiB of history pays several thousand before anything else happens, and that is assuming the
move fits in one month. **Egress is the kind of lock-in that grows silently**, because every month
the shop stores more than it deletes.

Two things change the number. Google announced in 2024 that it waives these charges for a customer
moving all of its data off Google Cloud, on application and under its own conditions; read the
current terms before counting on it. And data can also leave on physical devices, which turns a
network price into a shipping one for the very large cases.

## Rewriting what touches Google

This is the part the seams of the previous section exist to shrink. Count the call sites: every
import of a Google client library, every resource in the Terraform, every IAM binding. For the shop
as designed in lesson 22, that is the one module that publishes to Pub/Sub, the Eventarc trigger,
the Cloud Scheduler job, the Terraform for four services, and the permissions between them. Weeks,
not months, because the services themselves are containers.

A shop that called Firestore from forty places, or put business rules in Cloud Tasks retry
settings, would count differently, and the count is the estimate.

## Running both at once

**No real migration switches over in a night.** For weeks, data is copied and kept in step, traffic
moves service by service, and both providers bill for everything that is running twice. A rough
rule is that the overlap costs as much as the systems themselves for its duration, so a two-month
overlap on a 2,000-dollar monthly bill is about 4,000 dollars of duplicate infrastructure, plus the
time of whoever is watching both.

## The exit, priced

Put together, the cost of leaving is a number with three terms: egress from the program, weeks of
rewriting from the call-site count, and the overlap from the bill. **Writing that number down once
a year turns lock-in from a fear into a quantity**, and a quantity that is growing faster than the
system is the one worth acting on.
