---
title: Counters, rates and averages — the three ways a number lies
version: 1
---

Every number in this lesson is one of three things, and reading one as another is
how a perfectly correct figure gives a wrong answer.

| | |
|---|---|
| a **counter** | total since boot. Only differences mean anything |
| a **rate** | a counter, divided by the time between two samples |
| a **gauge** | the value right now |

## Counters

```
ana@vm:~$ ip -s link show eth0
…
    RX:  bytes packets errors dropped  missed   mcast
     365057734  262464      0       6       0       0
```

**365 megabytes received. Since when?** Since the interface came up, four and a
half hours ago. The number tells you nothing about whether the network is busy
now, and a bigger number does not mean a busier network — it means a longer
uptime.

The same applies to `/proc/stat`, `/proc/PID/io`, `/proc/diskstats` and every
`errors` column anywhere.

**A counter is only useful as a difference.** Two reads, ten seconds apart, and
subtract. Which is exactly what `vmstat 1`, `iostat 1`, `sar 1` and `pidstat 1`
do for you, and why they all take an interval.

## Which is why the first line is wrong

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 4  0      0 14507736  56092 1514136    0    0    71   358  431    1  3  0 97  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1074  218 100  0  0  0  0  0
 5  0      0 14507736  56092 1514136    0    0     0     0 1062  188 100  0  0  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1083  296 100  0  0  0  0  0
```

The first row says `us 1, id 97` on a machine that is pinned at 100%. **It has
no previous sample to subtract from, so it divides the counter by the uptime**
and prints the average since boot.

This is true of `vmstat`, `iostat`, `sar` and `mpstat`, and it is the single
most common misreading in performance work. Two habits fix it permanently:

```sh
vmstat 1 5 | tail -4         # drop the first
iostat -xz 2 2 | tail -6     # same
```

**And never run these without an interval.** `vmstat` on its own prints exactly
the useless line and nothing else.

## Averages hide the thing you are looking for

An average over five minutes cannot show you a two-second stall, and a two-second
stall is what the user complained about.

```
ana@vm:~$ mpstat -P ALL 1 1
…
11:25:36     all  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       0  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
```

The `all` row is an average across four cores. Here every core is at 100% so the
average is honest — but **one core at 100% and three idle averages to 25%**, and
that is the most common shape of a real problem: a program that is not threaded,
on a machine with plenty of spare capacity.

The same hiding happens in time as well as across cores:

| | |
|---|---|
| `sar` at its default | one sample every ten minutes. Sees nothing shorter |
| `vmstat 1` | one a second. Sees a two-second stall |
| `vmstat 5` | one every five. **Might miss it entirely** |

**Sample at the timescale of the complaint.** "It hangs for a second every
minute" needs `vmstat 1` for two minutes, not `sar` for an hour.

## Percentiles, where you can get them

An average latency of 5 ms with a 99th percentile of 4 seconds is a system where
one request in a hundred is unusable and the average says everything is fine.

The command-line tools in this lesson give you averages — `await` is a mean.
`iostat -x` has no percentile, and neither does `vmstat`. **That is a real limit
of this whole toolkit**, and the honest answer to "is the tail bad" is either
application metrics, `bpftrace`'s histograms, or `perf`.

Which is worth saying plainly: these tools find *which resource* and *which
process*. For *which request*, you need instrumentation that was there before
the incident.

## What to record before you need it

The argument for `sar`'s collector, in one sentence: **you cannot sample the
past.**

```sh
systemctl enable --now sysstat        # collect every ten minutes, keep a month
sar -u -f /var/log/sysstat/sa15       # processor, on the 15th
sar -d -p -f /var/log/sysstat/sa15    # disks, with real names
sar -n DEV -f /var/log/sysstat/sa15   # network
```

Ten minutes of granularity is coarse and it is infinitely better than nothing at
three in the morning, when the machine is healthy again and nobody can say what
it was doing.
