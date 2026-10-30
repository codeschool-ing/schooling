---
title: Deciding from utilisation, by hand
version: 1
---

**A rightsizing decision is a rule applied to a distribution, and the rule should be written down.** Google's
recommendations apply rules the shop cannot read; writing one's own makes the trade explicit and arguable. The
program below generates fourteen days of hourly CPU and memory for the shop's four Compute Engine machines and
applies a rule: **idle** below 2% CPU at the 95th percentile, **oversized** below 40% CPU and 50% memory at the 95th
percentile, otherwise keep. The data is generated, not measured; the rule is the one this section argues for. Write
it into `~/gcp/util.py`:

```python
# util.py
"""util.py: fourteen days of the shop's machines, and what to do with each.

Utilisation is generated, seeded: one sample an hour per machine. The rules
are the ones the lesson argues for, written down so they can be argued with.
"""
import random
import statistics

rng = random.Random(9)
MACHINES = {               # name: (type, vCPUs, GB, typical CPU %, typical memory %)
    "batch-1": ("e2-standard-4", 4, 16, 55, 60),
    "batch-2": ("e2-standard-4", 4, 16, 12, 22),
    "reports": ("e2-standard-8", 8, 32, 9, 18),
    "old-migration": ("e2-standard-2", 2, 8, 0.5, 6),
}


def p95(values):
    return statistics.quantiles(values, n=20)[18]


print(f'{"machine":<15}{"type":<15}{"cpu p95":>8}{"mem p95":>8}  verdict')
for name, (kind, cpus, gb, cpu, mem) in MACHINES.items():
    c = [max(0.0, rng.gauss(cpu, cpu / 3)) for _ in range(14 * 24)]
    m = [max(0.0, rng.gauss(mem, mem / 6)) for _ in range(14 * 24)]
    cp, mp = p95(c), p95(m)
    if cp < 2:
        verdict = "idle: stop, then delete"
    elif cp < 40 and mp < 50:
        verdict = f"oversized: {cpus // 2} vCPUs, {gb // 2} GB would do"
    else:
        verdict = "keep"
    print(f'{name:<15}{kind:<15}{cp:>7.1f}%{mp:>7.1f}%  {verdict}')
```

```
ana@laptop:~/gcp$ python3 util.py
machine        type            cpu p95 mem p95  verdict
batch-1        e2-standard-4     86.6%   77.4%  keep
batch-2        e2-standard-4     18.7%   27.9%  oversized: 2 vCPUs, 8 GB would do
reports        e2-standard-8     13.4%   23.0%  oversized: 4 vCPUs, 16 GB would do
old-migration  e2-standard-2      0.8%    7.4%  idle: stop, then delete
```

Four machines, four different answers:

- **`batch-1`** reaches 86.6% CPU at the 95th percentile. It is working; shrinking it would make the batch slower and
  probably later. Keep.
- **`batch-2`** and **`reports`** use under a fifth of their CPU and under a third of their memory even at the 95th
  percentile. Each would fit in half the machine. E2 machines are priced per vCPU and per gigabyte, so **half the
  machine is half the price**, for the same work.
- **`old-migration`** has not done anything in fourteen days: 0.8% CPU is the operating system talking to itself. It
  is the resource nobody owns, which lesson 23 is about finding.

## Why the 95th percentile, and why fourteen days

The **mean would shrink machines that have busy hours**: `batch-1` might average 55% and peak at 90%, and sizing it to
the average would make every peak slow. The 95th percentile ignores the top 5% of hours (about 17 hours in fourteen
days), which is a deliberate allowance for spikes the machine can absorb by running slower for a while. A machine
whose top hours must never slow down is sized to its maximum instead, and the rule says so in a comment beside it.

**Fourteen days** includes two of every weekday. A machine measured over three quiet days looks idle the week before
the monthly report runs on it. For anything with a monthly cycle, the window is a month or more, and the machine's
owner is asked before anything is changed: they know about the 1st of the month, and no utilisation graph does.
