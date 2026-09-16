---
title: The processor, and the seven columns that say where it went
version: 1
---

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 4  0      0 14507736  56092 1514136    0    0    71   358  431    1  3  0 97  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1074  218 100  0  0  0  0  0
 5  0      0 14507736  56092 1514136    0    0     0     0 1062  188 100  0  0  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1083  296 100  0  0  0  0  0
```

**`vmstat 1` is the first command to run on a machine somebody is complaining
about**, and the most important thing about it is on the first line.

## Throw the first line away

Look at the first row: `us 1`, `id 97`. The machine was at 100% on the three
rows underneath, and the first row says it was idle.

**The first line of `vmstat` is an average since boot.** So is the first block
of `iostat`, and the first line of `sar`. Nothing is wrong; you are reading four
and a half hours of history and mistaking it for now.

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
sells you the machine. **Every capture in this lesson shows `st 0`**, because
nothing here is contended; there is no honest way to produce a steal figure on
this machine, so there is no transcript of one.

## Per core

An average hides the case that matters most: one thread pinned at 100% while
seven cores idle, which averages to 12.5% and looks fine.

```
ana@vm:~$ mpstat -P ALL 1 1
Linux 6.18.44-fc-v33 (vm)       09/15/26        _x86_64_        (4 CPU)

11:25:35     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
11:25:36     all  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       0  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       1  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       3  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
```

Four loops, four cores, all four at 100%. **`mpstat -P ALL 1` is how you tell a
machine that is out of processor from a program that is single-threaded** — and
the second is far more common than the first.

`%irq` and `%soft` are interrupt handling. High `%soft` on one core is usually
network interrupts not being spread across cores.

## `top`, for when you want one screen

```
ana@vm:~$ top -b -n 1 | head -12
top - 11:28:24 up  4:33,  0 user,  load average: 0.63, 1.42, 0.84
Tasks:  86 total,   4 running,  82 sleeping,   0 stopped,   0 zombie
%Cpu(s): 73.2 us,  0.0 sy,  0.0 ni, 24.4 id,  0.0 wa,  0.0 hi,  2.4 si,  0.0 st
MiB Mem :  16095.9 total,  14135.3 free,    652.0 used,   1558.0 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15443.9 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
16258 ana       20   0    4720   3380   3080 R 100.0   0.0   0:04.21 bash
16259 ana       20   0    4720   3348   3048 R 100.0   0.0   0:04.20 bash
16260 ana       20   0    4720   3388   3088 R 100.0   0.0   0:04.21 bash
    1 root      20   0   26536   4240   3844 S   0.0   0.0   0:19.51 process_api
    2 root      20   0       0      0      0 S   0.0   0.0   0:00.01 kthreadd
```

Lesson 6 section 07 covered reading `top`. Two things for this lesson:

**`top -b -n 1` is the batch form** — one screenful, no cursor addressing — which
is what you use in a script, over `ssh`, or in a transcript like this one.

**`%CPU` is per core, so it goes past 100.** A `%CPU` of 380 on this machine is
one process using nearly all four cores; it is not a bug and not an error.

And the line `Tasks: 86 total, 4 running` is the same count the load average
feeds on. PID 1 being `process_api` rather than `systemd` is this machine being
a sandbox, as lesson 5 section 08 explained — the numbers are real, the process list is
this container's.

## When it is the processor

```sh
vmstat 1                    # is r above the core count, sustained
mpstat -P ALL 1             # is it every core, or one
pidstat -u 1                # which process
```

Three commands, in that order, and the next one after them is
`perf top` — which is a profiler and beyond this lesson's scope, but is the
honest answer to "which *line of code*".
