---
title: Swap, which is not the problem and is not the fix
version: 1
---

```
ana@vm:~$ swapon --show; echo "(nothing above means no swap)"
(nothing above means no swap)
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       657Mi        13Gi        11Mi       1.5Gi        15Gi
Swap:             0B          0B          0B
```

**This machine has no swap at all**, which is common on cloud instances and
almost universal in containers. That means the transcripts in this section stop
here: there is no honest way to show `si`/`so` moving on a machine with nowhere
to swap to, so the rest of this section describes rather than demonstrates, and
says so.

## What swap is for

Swap is disk used as an overflow for memory. The kernel writes pages that have
not been touched for a long time out to it, freeing the physical page for
something that is being used.

**The purpose is not "more memory".** Disk is thousands of times slower than
memory; a machine genuinely running out and swapping to make up the difference
is not slow, it is stopped. The purpose is to get *cold* pages — a daemon's
startup code that ran once at boot, a library nothing has called since — out of
the way, so physical memory can hold things that are in use.

Which is why a machine with swap in use is not necessarily in trouble:

| | |
|---|---|
| `Swap used: 400 MB`, `si`/`so` zero | 400 MB of cold pages are parked. **Healthy** |
| `Swap used: 400 MB`, `si`/`so` busy | pages are moving in and out continuously. **Thrashing** |

**`swapon --show` tells you how much is parked; `vmstat`'s `si` and `so` tell
you whether anything is moving.** The second is the measurement, and the first
is the one people alarm on.

## The columns

```
 r  b   swpd   free   buff  cache   si   so    bi    bo
```

| | |
|---|---|
| `swpd` | how much is currently swapped out — the parked figure |
| `si` | pages swapped **in** per second — a program touched something that was parked |
| `so` | pages swapped **out** per second — the kernel is making room |

Sustained non-zero `si` **and** `so` together is thrashing: the machine is
spending its time moving pages rather than running code, and the symptom is that
everything is slow and no single process looks guilty.

On this machine those columns are zero on every capture in this lesson, for the
reason at the top.

## `swappiness`

```sh
cat /proc/sys/vm/swappiness         # 60 on most distributions
sysctl -w vm.swappiness=10          # until reboot
```

It is a number from 0 to 100 that biases the kernel between reclaiming page
cache and swapping out anonymous pages. Higher swaps more readily.

**It is not a percentage of memory and it is not a threshold.** Setting it to 0
does not disable swap; it makes the kernel avoid swapping until it is nearly out
of options, which on some kernels means the OOM killer arrives sooner than it
otherwise would.

The default of 60 is fine for almost everything. Database vendors recommend
1 or 10 because a swapped-out buffer pool is a disaster; that is a specific
recommendation for a specific workload, not general advice.

## No swap at all

Containers, most Kubernetes nodes, and plenty of cloud instances run with none,
which is what this machine does. The trade is explicit:

**With swap**, a machine under memory pressure gets slow, and stays alive long
enough for you to notice and act.

**Without swap**, a machine under memory pressure gets killed — the OOM killer
picks a process and ends it, immediately, which is the next section. There is no
slow degradation and no warning.

Neither is wrong. **The one that is wrong is not knowing which you have**, and
`swapon --show` answers that in one command.

## What to actually do about swap

| | |
|---|---|
| swap in use, `si`/`so` quiet | nothing. This is the feature working |
| `si`/`so` sustained | find the process using the memory. It is a memory problem, not a swap one |
| no swap, and processes dying | the next section |

**Adding swap does not fix a memory shortage**, it converts it from a crash into
a slowdown. Sometimes that is exactly the trade you want; it is still a trade.
