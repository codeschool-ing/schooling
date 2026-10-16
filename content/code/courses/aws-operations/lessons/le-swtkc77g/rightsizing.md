---
title: Rightsizing from two weeks of use
version: 1
---

An instance twice the size it needs costs twice as much every hour, and nothing on the bill says so.
**Rightsizing** is choosing the size from what the workload uses rather than from what somebody guessed
at launch. It needs the use, and two numbers per instance answer most of it: **CPU in the busiest hours**,
and **the most memory it ever held**.

The shop's two weeks, made up by a program so the file is the same for everybody, four instances hour by
hour:

```python
# fortnight.py: writes usage.csv, two made-up weeks of the shop's instances, hour by hour
import csv
import random

rand = random.Random(23)
# name, size, typical CPU % in working hours and at night, memory % in use
fleet = [("api-1", "m7g.xlarge", 22, 6, 35), ("api-2", "m7g.xlarge", 24, 7, 36),
         ("worker", "m7g.2xlarge", 70, 55, 62), ("reports", "m7g.xlarge", 9, 2, 71)]
with open("usage.csv", "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["hour", "instance", "size", "cpu", "memory"])
    for hour in range(14 * 24):
        busy = 9 <= hour % 24 < 18 and hour // 24 % 7 < 5
        for name, size, day, night, mem in fleet:
            cpu = (day if busy else night) * rand.uniform(0.6, 1.6)
            w.writerow([hour, name, size, round(min(cpu, 100), 1), round(mem * rand.uniform(0.9, 1.1), 1)])
print("usage.csv:", 14 * 24 * len(fleet), "rows")
```

And the rule, in `rightsize.py`:

```python
# rightsize.py: a size for each instance from two weeks of CPU and memory
import collections
import csv

PRICE = {"m7g.large": 0.1301, "m7g.xlarge": 0.2601, "m7g.2xlarge": 0.5202}  # USD an hour, on demand
SMALLER = {"m7g.xlarge": "m7g.large", "m7g.2xlarge": "m7g.xlarge"}

cpu, memory, size = collections.defaultdict(list), collections.defaultdict(list), {}
for row in csv.DictReader(open("usage.csv")):
    cpu[row["instance"]].append(float(row["cpu"]))
    memory[row["instance"]].append(float(row["memory"]))
    size[row["instance"]] = row["size"]

print(f"{'instance':<9} {'size':<12} {'p95 cpu':>7} {'max mem':>7}  advice")
saved = 0.0
for name in sorted(cpu):
    p95 = sorted(cpu[name])[int(len(cpu[name]) * 0.95)]
    top = max(memory[name])
    smaller = SMALLER.get(size[name])
    # half the size doubles both: it must still leave room in the busiest hours
    if p95 >= 90:
        advice = "up: the busiest hours are at the limit"
    elif smaller and p95 * 2 < 80 and top * 2 < 85:
        advice = f"down to {smaller}, {(PRICE[size[name]] - PRICE[smaller]) * 730:.2f} USD a month less"
        saved += (PRICE[size[name]] - PRICE[smaller]) * 730
    elif smaller and p95 * 2 < 80:
        advice = "keep: memory would not fit in half"
    else:
        advice = "keep"
    print(f"{name:<9} {size[name]:<12} {p95:>6.1f}% {top:>6.1f}%  {advice}")
print(f"saved a month: {saved:.2f} USD")
```

```
ana@laptop:~/aws/rightsize$ python3 fortnight.py
usage.csv: 1344 rows
ana@laptop:~/aws/rightsize$ python3 rightsize.py
instance  size         p95 cpu max mem  advice
api-1     m7g.xlarge     31.1%   38.4%  down to m7g.large, 94.90 USD a month less
api-2     m7g.xlarge     34.1%   39.6%  down to m7g.large, 94.90 USD a month less
reports   m7g.xlarge     12.6%   78.0%  keep: memory would not fit in half
worker    m7g.2xlarge   100.0%   68.2%  up: the busiest hours are at the limit
saved a month: 189.80 USD
```

## Why these numbers

**The 95th percentile of CPU, not the average.** An average of two weeks counts nights and weekends, and
the API's average is under 15%; sized to that, it would fall over every weekday at eleven. The p95 is the
busiest hours less the rarest spikes. **The maximum of memory, not a percentile**, because a process that
runs out of memory does not slow down, it is killed.

Halving the size halves both the vCPUs and the memory, so both percentages double. The API at a p95 of
31% would run at about 62% on half the machine, with room for a busier week; its memory at 38% becomes
77%, inside the limit. **Two instances, 94.90 USD a month each**, by the price list's `m7g` lines.

`reports` uses almost no CPU and three quarters of its memory: halving it would leave no room. Its real
answer is a different family, `r7g`, with twice the memory per vCPU, which is a choice a size table does
not show. And `worker` is the opposite case: its busiest hours are at 100%, which is **underprovisioned**.
Rightsizing finds those too, and a team that only ever reads the *down* column runs its busiest service
on a machine that is too small.

## What this program does not see

**Memory is not a metric EC2 reports.** CPU, network and disk come from the hypervisor; memory is inside
the operating system, and CloudWatch has it only if the CloudWatch agent publishes it from the
instance. Without it, any rightsizing, Compute Optimizer's included, decides on CPU alone and can
recommend a size the workload's memory will not fit. That is the first thing to install before trusting a
recommendation down.
