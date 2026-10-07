---
title: The processor, and the seven columns that say where it went
version: 2
---

Start the busy loops again:

```sh
cd ~/work/load
./spin.sh &
sleep 5
```

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 5  0      0 15719688   6984 371660    0    0   137 14614 1053    2  9  2 89  1  0  0
 4  0      0 15719516   6984 371660    0    0     0     0 1030  202 100  0  0  0  1  0
 4  0      0 15719436   6984 371660    0    0     0     0 1045  231 99  0  0  0  1  0
 4  0      0 15719436   6984 371660    0    0     0     0 1052  245 99  0  0  0  1  0
```

**`vmstat 1` is the first command to run on a machine somebody is complaining
about**, and the most important thing about it is on the first line.

## Throw the first line away

Look at the first row: `us 9`, `id 89`. The machine was at 99% on the three
rows underneath, and the first row says it was idle.

**The first line of `vmstat` is an average since boot.** So is the first block
of `iostat`, and the first line of `sar`. Nothing is wrong; you are reading three
hours of history and mistaking it for now.

This is the single most common misreading in this lesson, and the fix is
mechanical: **run it with an interval and ignore the first sample.**

## The columns worth knowing

| | |
|---|---|
| `r` | processes **runnable** — on a core or waiting for one |
| `b` | processes **blocked**, in uninterruptible sleep |
| `si` `so` | pages swapped **in** and **out** per second. The swap section |
| `bi` `bo` | blocks read from and written to devices per second |
| `in` `cs` | **interrupts** and **context switches** per second |

`r` against the core count is the saturation number the load average is not:
`r 4` on four cores is full, `r 40` is a queue.

`cs` is worth a glance. On this machine, busy-looping, it is about 200 per
second. A machine doing tens of thousands of context switches per second is
spending its time changing its mind, which is usually too many threads or a lock
that everybody wants.

## The CPU columns

```
us sy id wa st gu
```

| | |
|---|---|
| `us` | **user** — your programs' own code |
| `sy` | **system** — the kernel, on their behalf. Syscalls, page faults |
| `id` | **idle** — nothing to run |
| `wa` | **iowait** — idle, *and* at least one task was blocked on disk |
| `st` | **steal** — the hypervisor gave your slice to somebody else |
| `gu` | **guest** — time running a virtual machine, if this machine is a host |

`top` and `mpstat` split out one more, `ni` — user time spent by processes with
a positive nice value, which is lesson 6 section 12's priority showing up as a column.

Three of these are worth reading carefully.

**`sy` high with `us` low** means the kernel is doing the work: too many small
reads, too many processes being created, a syscall in a tight loop. `strace -c`
on the process names the syscall.

**`wa` is not a measure of disk load.** It is idle time that happened while
something was waiting for disk. A machine with `wa 50` and one blocked process
may be perfectly healthy; a machine with `wa 0` may have a saturated disk if the
processors are busy enough that there is no idle time to attribute. `wa` is a
hint to look at `iostat`, not a verdict.

**`st` is the one you cannot fix.** It means you are on a virtual machine and
the host is overcommitted — your processor time is being given to another
tenant. Anything above a few per cent sustained is a conversation with whoever
sells you the machine. **The captures in this lesson show `st` at 1 or 2 while
the loops run**, because this machine is itself a virtual machine on a shared
host and a little of its time is going elsewhere. That is the harmless end of
the scale; the same column at 20 is somebody else's workload slowing down yours.

## Per core

An average hides the case that matters most: one thread pinned at 100% while
seven cores idle, which averages to 12.5% and looks fine.

```
ana@vm:~$ mpstat -P ALL 1 1
Linux 6.18.44-fc-v77 (vm)       10/07/26        _x86_64_        (4 CPU)

13:47:15     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
13:47:16     all   99.50    0.00    0.00    0.00    0.00    0.00    0.50    0.00    0.00    0.00
13:47:16       0   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
13:47:16       1  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
13:47:16       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
13:47:16       3   99.01    0.00    0.00    0.00    0.00    0.00    0.99    0.00    0.00    0.00

Average:     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
Average:     all   99.50    0.00    0.00    0.00    0.00    0.00    0.50    0.00    0.00    0.00
Average:       0   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
Average:       1  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
Average:       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
Average:       3   99.01    0.00    0.00    0.00    0.00    0.00    0.99    0.00    0.00    0.00
```

Four loops, four cores, each at 99 to 100% user time, and what is left over is
`%steal`, the column of the previous paragraph. **`mpstat -P ALL 1` is how you tell a
machine that is out of processor from a program that is single-threaded** — and
the second is far more common than the first.

`%irq` and `%soft` are interrupt handling. High `%soft` on one core is usually
network interrupts not being spread across cores.

## `top`, for when you want one screen

```
ana@vm:~$ top -b -n 1 | head -12
top - 13:40:26 up  3:10,  0 user,  load average: 1.20, 0.85, 0.94
Tasks:  98 total,   5 running,  92 sleeping,   0 stopped,   1 zombie
%Cpu(s): 95.5 us,  2.3 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si,  2.3 st
MiB Mem :  16094.7 total,  15378.4 free,    681.0 used,    310.6 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15413.7 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 9684 ana       20   0    4764   3384   3124 R  90.9   0.0   0:05.12 bash
 9685 ana       20   0    4764   3376   3120 R  90.9   0.0   0:05.15 bash
 9687 ana       20   0    4764   3360   3108 R  90.9   0.0   0:05.11 bash
 9686 ana       20   0    4764   3412   3156 R  81.8   0.0   0:05.03 bash
  102 root      20   0 2097272  42988  27820 S   9.1   0.3   0:08.87 environment-man
```

Lesson 6 section 07 covered reading `top`. Two things for this lesson:

**`top -b -n 1` is the batch form** — one screenful, no cursor addressing — which
is what you use in a script, over `ssh`, or in a transcript like this one.

**`%CPU` is per core, so it goes past 100.** A `%CPU` of 380 on this machine is
one process using nearly all four cores; it is not a bug and not an error.

And the line `Tasks: 98 total, 5 running` is the same count the load average
feeds on: four loops and `top` itself. `environment-man` at the bottom is this
machine being a sandbox, as lesson 5 section 08 explained — the numbers are real,
the process list is this container's.

## When it is the processor

```sh
vmstat 1                    # is r above the core count, sustained
mpstat -P ALL 1             # is it every core, or one
pidstat -u 1                # which process
```

Three commands, in that order, and the next one after them is
`perf top` — which is a profiler and beyond this lesson's scope, but is the
honest answer to "which *line of code*".

Stop the loops:

```sh
cd ~/work/load
pkill -f spin.sh
```
