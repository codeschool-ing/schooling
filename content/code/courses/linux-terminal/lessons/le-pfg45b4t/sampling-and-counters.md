---
title: Counters, rates and averages — the three ways a number lies
version: 2
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
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 02:fc:00:00:00:01 brd ff:ff:ff:ff:ff:ff
    RX:  bytes packets errors dropped  missed   mcast
    1003499627  214187      0       6       0       0
    TX:  bytes packets errors dropped carrier collsns
     333317247  179302      0       0       0       0
```

**A gigabyte received. Since when?** Since the interface came up, three hours
ago. The number tells you nothing about whether the network is busy
now, and a bigger number does not mean a busier network — it means a longer
uptime.

The same applies to `/proc/stat`, `/proc/PID/io`, `/proc/diskstats` and every
`errors` column anywhere.

**A counter is only useful as a difference.** Two reads, ten seconds apart, and
subtract. Which is exactly what `vmstat 1`, `iostat 1`, `sar 1` and `pidstat 1`
do for you, and why they all take an interval.

## Which is why the first line is wrong

With the busy loops running again:

```sh
cd ~/work/load
./spin.sh &
sleep 5
```

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 5  0      0 15676488  10324 394340    0    0   137 17341 1053    2  9  2 88  1  0  0
 4  0      0 15676488  10324 394340    0    0     0     0 1040  134 99  0  0  0  1  0
 4  0      0 15676488  10324 394340    0    0     0     0 1029  112 99  0  0  0  1  0
 4  0      0 15676488  10324 394340    0    0     0     0 1051  216 99  0  0  0  1  0
```

The first row says `us 9, id 88` on a machine that is pinned at 99%. **It has
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
Linux 6.18.44-fc-v77 (vm)       10/07/26        _x86_64_        (4 CPU)

13:50:49     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
13:50:50     all   98.75    0.00    0.25    0.00    0.00    0.00    1.00    0.00    0.00    0.00
13:50:50       0   97.03    0.00    0.99    0.00    0.00    0.00    1.98    0.00    0.00    0.00
13:50:50       1   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
13:50:50       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
13:50:50       3   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00

Average:     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
Average:     all   98.75    0.00    0.25    0.00    0.00    0.00    1.00    0.00    0.00    0.00
Average:       0   97.03    0.00    0.99    0.00    0.00    0.00    1.98    0.00    0.00    0.00
Average:       1   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
Average:       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
Average:       3   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
```

```sh
cd ~/work/load
pkill -f spin.sh
```

The `all` row is an average across four cores. Here every core is at 97 to 100% so the
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
