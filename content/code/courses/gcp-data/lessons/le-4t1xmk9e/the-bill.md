---
title: What a Dataflow job costs, and the stream that never stops
version: 1
---

**A Dataflow bill is the machines, by the second, plus what the service does for them.** Workers
are billed per vCPU-hour and per GiB-hour of memory, for as long as they exist, in increments of one
second; their disks are billed by the GiB-hour; and the shuffle, or in streaming the Streaming
Engine, has a line of its own. There is no charge per pipeline and none per element. **So a batch
job costs the minutes it runs, and a streaming job costs every hour of the month**, whether a single
order arrives or not.

## The prices, São Paulo

From `cloud.google.com/dataflow/pricing`, region `southamerica-east1`, in US dollars, read
2026-10-30:

| | batch | FlexRS | streaming |
|---|---:|---:|---:|
| per vCPU-hour | 0.084 | 0.0534 | 0.1035 |
| per GiB-hour of memory | 0.0053355 | 0.0033889 | 0.0053355 |
| per GiB of shuffle | 0.01747 | 0.01747 | — |
| Streaming Engine, per GiB processed (legacy billing) | — | — | 0.02858 |
| Streaming Engine, per Compute Unit (resource-based billing) | — | — | 0.134 |

**A discount in two steps is built into the batch shuffle line.** The page bills shuffle after a volume
adjustment: the first 250 GiB of a job at a quarter of their size, the next 4,870 GiB at half, and
the rest in full. A Standard Persistent Disk is 0.000081 dollars per GiB-hour on the same page, and
Dataflow Prime replaces the vCPU, memory and shuffle lines with one, the **Data Compute Unit**, at
0.09 dollars for batch and 0.134 for streaming. The page defines one DCU as comparable to what a job
uses running for an hour on a worker of 1 vCPU and 4 GB; you cannot set how many a job uses, only
read the count afterwards.

**FlexRS is the batch price for agreeing to wait.** The job may be started at any point within six
hours, on a mix of ordinary and preemptible machines, for a discount the page describes as about
40%. Its workers default to 2 vCPU and 7.5 GB, at least two of them.

## Five ways to run the same pipeline

The arithmetic, with the prices as constants and the assumptions in the open. Save it as
`~/gcp/dataflow_bill.py`:

`dataflow_bill.py`:

```python
"""dataflow_bill.py: five ways to run Quitanda's pipeline, priced.

Prices: cloud.google.com/dataflow/pricing, southamerica-east1, USD, read 2026-10-30.
The sizes and the hours are this lesson's assumptions, not measurements.
"""
BATCH = {'vcpu': 0.084, 'gib': 0.0053355}           # per vCPU-hour, per GiB-hour
FLEXRS = {'vcpu': 0.0534, 'gib': 0.0033889}
STREAMING = {'vcpu': 0.1035, 'gib': 0.0053355}
SHUFFLE_GIB = 0.01747                # batch: per GiB of shuffle, after the adjustment
STREAMING_ENGINE_GIB = 0.02858       # streaming: per GiB processed, legacy billing
DCU_BATCH = 0.09                     # Dataflow Prime, per batch DCU
DISK_GIB_HOUR = 0.000081             # Standard Persistent Disk
NIGHT, MONTH = 12 / 60, 730          # hours


def billable_shuffle(gib):
    """The page's adjustment: 75% off the first 250 GiB, 50% off the next 4,870."""
    return min(gib, 250) * 0.25 + min(max(gib - 250, 0), 4870) * 0.5 + max(gib - 5120, 0)


def workers(price, n, vcpu, gib, disk_gib, hours):
    return n * hours * (vcpu * price['vcpu'] + gib * price['gib'] + disk_gib * DISK_GIB_HOUR)


nights = [
    ('batch, 4 workers of 1 vCPU, 10 GiB shuffled',
     workers(BATCH, 4, 1, 3.75, 25, NIGHT) + billable_shuffle(10) * SHUFFLE_GIB),
    ('FlexRS, 2 workers of 2 vCPU, 10 GiB shuffled',
     workers(FLEXRS, 2, 2, 7.5, 25, NIGHT) + billable_shuffle(10) * SHUFFLE_GIB),
    ('Prime, if the night counts 0.8 DCUs',
     0.8 * DCU_BATCH + 4 * NIGHT * 25 * DISK_GIB_HOUR),
]
streams = [
    ('streaming, the default worker, 400 GB of disk',
     workers(STREAMING, 1, 4, 15, 400, MONTH)),
    ('streaming, 2 vCPU, Streaming Engine, 20 GiB',
     workers(STREAMING, 1, 2, 7.5, 30, MONTH) + 20 * STREAMING_ENGINE_GIB),
]
for name, night in nights:
    print(f'{name:<48}{night:>8.4f} a night {night * 30:>8.2f} a month')
for name, month in streams:
    print(f'{name:<48}{"":>17}{month:>8.2f} a month')
```

```
ana@laptop:~/gcp$ python3 dataflow_bill.py
batch, 4 workers of 1 vCPU, 10 GiB shuffled       0.1285 a night     3.86 a month
FlexRS, 2 workers of 2 vCPU, 10 GiB shuffled      0.0974 a night     2.92 a month
Prime, if the night counts 0.8 DCUs               0.0736 a night     2.21 a month
streaming, the default worker, 400 GB of disk                      384.30 a month
streaming, 2 vCPU, Streaming Engine, 20 GiB                        182.67 a month
```

**The nightly job is a few dollars a month in every form.** Four default batch workers for twelve
minutes, with 10 GiB through the shuffle, come to 0.1285 dollars a night: 0.8 vCPU-hours, 3 GiB-hours
of memory, 20 GiB-hours of disk, and 2.5 billable GiB of shuffle out of the 10, which is the
adjustment at work. FlexRS takes it to 0.0974 for being allowed to start late, and Prime would be
0.0736 if the night counted 0.8 DCUs, a number nobody can know before the run: **that line is an
estimate on the page's own comparison, not a price**.

**The stream is fifty to a hundred times the night.** One streaming worker with the defaults runs
730 hours a month: 4 vCPU at 0.1035, 15 GiB at 0.0053355 and 400 GB of disk, 384.30 dollars before a
single event is counted. With Streaming Engine, the disk drops to 30 GB and a worker of 2 vCPU and
7.5 GB is enough, 182.67 dollars with 20 GiB of data processed. The 20 GiB is this lesson's assumption. On legacy billing, Streaming Engine counts the bytes entering the pipeline, the bytes
passing between stages and the bytes kept for windows, so even Quitanda's few megabytes of events a
day are counted more than once, and how many times depends on the pipeline. **On resource-based
billing the line is in Compute Units instead**, 0.134 dollars each, and their number is metered by
Dataflow, not predictable from the page, so the program does not price it.

## What the comparison decides

**A streaming job earns its cost only if somebody acts on the minute.** For Quitanda's totals per
neighbourhood, read by an analyst in the morning, the nightly batch over the export answers the same
question for about 4 dollars a month against 183. A stream earns its 183 dollars when the totals feed something that
cannot wait for the morning, such as a screen in the warehouse that moves riders to the
neighbourhood whose orders are piling up. The pipeline does not
have to be written twice to keep that choice open, which was the point of the fourth section.

Three things change the numbers, and each is a pipeline option rather than code:

- **`--max_num_workers`**: autoscaling adds workers when the backlog grows, and the bill grows
  with them. A cap turns an unexpected surge into a delay instead of an invoice.
- **`--machine_type`**, together with `--enable_streaming_engine`: the default streaming worker is
  sized for a job that keeps its state on its own disk.
- **`--flexrs_goal=COST_OPTIMIZED`** on a batch job that can start within six hours.

Lesson 23 compares the same arithmetic with a Dataproc cluster running Spark, where the machines
are yours to size and to forget to switch off.
