---
title: Autoscaling, and the minute it bills
version: 1
---

**An autoscaled reservation is billed for the slots it has scaled to, not for the slots a query
used.** Between its baseline and its maximum, BigQuery's autoscaler adds slots when queries are
waiting for them and removes them when they are not. Google's documentation of the autoscaler says
it adds them in steps of 50, and the pricing page says each slot added is billed per second with a
minimum of one minute. Those two rules decide what a small query costs on slots, and they are
the reason a workload that looks cheap in slot-hours can be expensive on a bill.

**This section is a model, and it says so.** Nothing here runs BigQuery's autoscaler, and the real
one decides on its own when to scale up and how long to wait before scaling down, which the
documentation describes and does not put numbers on. What the model applies is the two documented
rules and nothing else: a query asking for 4 slots scales the reservation by 50, and those 50 are
billed for at least 60 seconds. It also assumes the worst case for those rules, a query arriving
alone, with nothing else running to share the slots it caused.

## The model

Save this as `~/gcp/autoscale.py`. It takes how many slots a query needs, for how many seconds, how
many such queries arrive in a month, and optionally the word `fluid`, which drops the minute:

`autoscale.py`:

```python
import math
import sys

STEP, MINIMUM_S = 50, 60  # slots are added in steps of 50, and billed for at least a minute
SLOT_HOUR = 0.093         # USD, Enterprise, pay as you go, southamerica-east1, read 2026-10-30

slots, seconds, count = int(sys.argv[1]), float(sys.argv[2]), int(sys.argv[3])
minimum = 0 if sys.argv[4:] == ['fluid'] else MINIMUM_S
used = slots * seconds * count / 3600
billed = math.ceil(slots / STEP) * STEP * max(seconds, minimum) * count / 3600
print(f'{count:,} queries of {slots} slots for {seconds:g} s')
print(f'  slot-hours used   {used:10,.2f}   {used * SLOT_HOUR:9,.2f} USD')
print(f'  slot-hours billed {billed:10,.2f}   {billed * SLOT_HOUR:9,.2f} USD')
```

Two workloads. Quitanda's store dashboard, 100,000 small queries a month, each needing 4 slots for 3
seconds, priced with the minute and then with fluid scaling; and a nightly transformation, 300 large
queries a month, each needing 400 slots for two minutes. Then what the dashboard's queries cost on
demand instead, each billed at the 10 MB minimum of the last section:

```
ana@laptop:~/gcp$ python3 autoscale.py 4 3 100000
100,000 queries of 4 slots for 3 s
  slot-hours used       333.33       31.00 USD
  slot-hours billed  83,333.33    7,750.00 USD
ana@laptop:~/gcp$ python3 autoscale.py 4 3 100000 fluid
100,000 queries of 4 slots for 3 s
  slot-hours used       333.33       31.00 USD
  slot-hours billed   4,166.67      387.50 USD
ana@laptop:~/gcp$ python3 autoscale.py 400 120 300
300 queries of 400 slots for 120 s
  slot-hours used     4,000.00      372.00 USD
  slot-hours billed   4,000.00      372.00 USD
ana@laptop:~/gcp$ python3 -c "print(100000 * 10 * 2**20 / 2**40)"
0.95367431640625
```

**The dashboard used 333 slot-hours and was billed for 83,333, two hundred and fifty times as many.**
Each query asked for 4 slots and caused 50, and used them for 3 seconds out of the 60 it was billed
for: 50 ÷ 4 × 60 ÷ 3 is 250. At the Enterprise price that is 7,750 USD a month for 31 USD of work.
**Fluid scaling takes the minute away** and leaves the steps of 50, and the bill falls to 387.50 USD,
still twelve and a half times the work. **On demand, the same 100,000 queries are 0.95 TiB**, each
billed at its 10 MB minimum, which fits inside the free TiB and costs nothing.

**The nightly transformation is the opposite case.** Four hundred slots is a whole number of steps
and two minutes is more than the minimum, so what it used and what it was billed are the same: 4,000
slot-hours and 372 USD. A workload made of long, wide queries pays for what it uses; a workload made of
short, narrow ones pays for the rounding.

## What the model leaves out

**Real queries overlap**, and that is what rescues the dashboard on a real reservation. When tiles
refresh together, their queries share the 50 slots the first of them caused, and the minute is paid
once for all of them rather than once each. The model's 250 is the ceiling of the effect, for queries
spread so thinly that none of them meets another, and what a real dashboard pays falls somewhere
under it. Where it falls is in `INFORMATION_SCHEMA.JOBS` and in the reservation's own usage views,
which a real project reads before it decides.

**A baseline changes the arithmetic as well.** Slots in the baseline are paid for every hour, used or
not, and queries take them first; the autoscaler only adds slots above it. A reservation with a
baseline of 100 and a maximum of 300 pays for 100 slots all month and for the scaled slots above 100
only while they are there. A baseline sized to the load that never stops, with autoscaling above it
for the load that comes and goes, is how Google's documentation suggests the two be combined, and it
is the same shape as the twin choice every pricing model in this course has had: pay for the floor
and rent the peaks.

**Idle slots can also be lent.** In Enterprise and Enterprise Plus, slots a reservation's baseline
owns and is not using can be borrowed by other reservations of the same administration project, so
that the night's transformations can run on capacity the analysts paid for and left idle. Whether a
reservation lends and borrows is a setting of the reservation, and none of it can be shown here.
