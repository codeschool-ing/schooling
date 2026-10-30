---
title: Families, and the ratio that decides between them
version: 1
---

The wrong way to pick a machine is to pick a size and then a family. **The family comes first,
because it decides two things a size cannot change: the ratio of memory to processor, and the
price of each.** Google groups its series into four families, and nearly everything a small team
runs belongs in the first.

## The four families

**General purpose** is the default, and it has three tiers that differ in what they promise:

- **E2** is the cheapest per vCPU. Google chooses the processor, Intel or AMD, from whatever the
  zone has. There are no sustained use discounts on E2, the
  automatic discount of up to 30% that some other series earn by running for more than a quarter
  of the month; the price is low to begin with instead.
- **N4, N2 and N2D** fix the processor, so a benchmark run today is still true next month. N4 is
  the newest; it uses only Hyperdisk, the disk family lesson 3 compares with persistent disks.
- **C4, C4A and C4D** are the performance tier, with the newest processors and the highest network
  bandwidth. **C4A is Arm**, Google's Axion, which means your images and any compiled
  dependency must be built for `arm64`.

**Compute optimised** (C2, C2D, H3, H4D) is for work that is mostly arithmetic: simulations,
encoders, high-performance computing. **Memory optimised** (M1 to M4, X4) starts where the
general-purpose families stop, at around a terabyte of memory, for databases that keep everything
in memory. **Accelerator optimised** (A2, A3, G2, G4) carries GPUs and is lesson 2's subject.

## What the ratio costs

Here is every 2-vCPU machine on the sheet, from the program in section 03:

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E "standard-2|highcpu-2|highmem-2"
  e2-standard-2   2 vCPU   8 GiB    0.06701142       48.92    0.040212
  e2-highcpu-2    2 vCPU   2 GiB    0.04947024       36.11           -
  e2-highmem-2    2 vCPU  16 GiB    0.09039966       65.99           -
  n4-standard-2   2 vCPU   8 GiB        0.0907       66.21    0.053652
  n4-highcpu-2    2 vCPU   4 GiB       0.07654       55.87           -
  n4-highmem-2    2 vCPU  16 GiB       0.11902       86.88           -
  n2-standard-2   2 vCPU   8 GiB      0.097118       70.90    0.058256
  n2d-standard-2  2 vCPU   8 GiB      0.084492       61.68           -
  c4-standard-2   2 vCPU   7 GiB      0.096866       70.71    0.057979
  c4a-standard-2  2 vCPU   8 GiB        0.0898       65.55    0.044388
```

Read it twice: across, for the ratio, and down, for the tier. **Across**, memory is most of what
changes the price inside a series: `e2-highcpu-2` with 2 GiB is 36.11 a month, `e2-standard-2`
with 8 GiB is 48.92, `e2-highmem-2` with 16 GiB is 65.99. **Down**, the same 8 GiB and 2 vCPUs
cost 48.92 on E2, 61.68 on N2D, 66.21 on N4 and 70.90 on N2. What the extra 22 dollars a month
buys on N4 is a processor that stays the same and does more per vCPU, which matters when the
machine is busy and matters not at all when it is idle.

So the ratio is the first measurement to make, and it comes from the program, not from the
catalogue. A service that settles at 11 GiB of memory under real load with two busy vCPUs has
three honest choices on E2:

| machine | vCPU | GiB | per month | what is wasted |
|---|---|---|---|---|
| `e2-standard-4` | 4 | 16 | 97.84 | two vCPUs nobody uses |
| `e2-highmem-2` | 2 | 16 | 65.99 | 5 GiB of headroom |
| a custom type | 2 | 12 | section 06 | nothing, at a premium |

Choosing the size first, "it needs more memory, so the next size up", lands on the first row and
pays 31.85 a month more than the second for processors that sit idle. **Over a year that is 382
dollars for one machine**, and a group of them multiplies it.

## Where each one fits

The rule of thumb that survives most cases is short. **Start on E2**, because it is cheapest and
the work of a small team (a web application, a worker, a build agent) rarely notices which
processor it got. **Move to N4 or C4** when a measurement says the processor is the bottleneck, or
when the software must not see the processor change under it. **Consider C4A** when the software
already runs on Arm, because at the same vCPUs and more memory it costs less than C4. And reach
for the other families only for the workload they are named after.
