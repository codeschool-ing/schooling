---
title: Load average, which is not a percentage and not about the processor
version: 1
---

```
ana@vm:~$ uptime
 11:21:12 up  4:26,  0 user,  load average: 0.44, 0.14, 0.05
ana@vm:~$ cat /proc/loadavg
0.44 0.14 0.05 1/119 15413
```

Three numbers: the average over one minute, five minutes and fifteen minutes.
`/proc/loadavg` adds two more — **running processes / total processes**, and the
last process id allocated.

## What is being averaged

**On Linux, the load average counts processes in two states:**

| | |
|---|---|
| **R** — runnable | running on a core, or waiting for one |
| **D** — uninterruptible sleep | waiting on a disk, usually |

Section 89 named those two states. **The D is the part that surprises everyone**,
and it is why load average is not a processor metric: a machine with an idle
processor and a saturated disk has a high load average, and a machine using
every core with nothing queued has a load average equal to its core count.

Other Unixes do it differently. On Solaris and the BSDs the load average is the
run queue alone, which makes it a processor number there and not here. If you
learned this on another system, unlearn it for Linux.

## Compare it to the core count

```
ana@vm:~$ uptime
 11:24:00 up  4:29,  0 user,  load average: 3.64, 1.66, 0.64
ana@vm:~$ nproc
4
```

That is this machine with four busy loops running. **3.64 on four cores is a
machine fully used and not queueing.** The same 3.64 on a single-core machine
would mean three and a half processes waiting their turn for every one running.

So the only sane reading is the ratio:

| | |
|---|---|
| load ≈ cores | fully used, nothing waiting |
| load < cores | idle capacity |
| load ≫ cores | something is queueing — but for *what* is a separate question |

There is no threshold. "Load 8" on an 8-core machine is fine; on a 2-core
machine it is a problem; on a machine with a stuck NFS mount it is neither,
because every process blocked on that mount is counted and none of them is using
anything.

## The three numbers are a direction

The one, five and fifteen minute figures matter as a shape rather than as
values:

| | |
|---|---|
| `0.44, 0.14, 0.05` | rising. Something started recently |
| `0.64, 1.66, 3.64` | falling. Whatever it was is over |
| `3.6, 3.6, 3.6` | steady. This is what the machine does |

**Reading one number and not the other two is how you get called about a spike
that ended forty minutes ago.**

## Where it misleads badly

Here is this machine writing a gigabyte a second to its disk:

```
ana@vm:~$ uptime
 11:31:26 up  4:36,  0 user,  load average: 1.39, 1.20, 0.84
ana@vm:~$ vmstat 1 3
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 0  1      0 14476076  56304 1542856    0    0    69  5180  452    1  3  0 96  0  0  0
 0  1      0 14477244  56304 1542856    0    0     0 883716 3874 4433  6  5 67 22  0  0
 0  1      0 14485424  56304 1542856    0    0     0 980992 3815 4290  2  4 72 22  0  0
```

**Load 1.39 on a four-core machine, and the disk is at 93% utilisation.** That
93% is `iostat`'s, from section 184; `vmstat` does not carry it. On the load
average alone you would close the ticket. The `b 1` and the `wa 22` are the real
story, and they are read in section 179 and section 184.

It goes the other way too. A machine wedged on a dead network filesystem will
show a load average of 40 with every processor idle, because forty processes are
sitting in `D` waiting for a server that is not answering. Nothing is consuming
anything; nothing is going to finish either.

## What to use instead

**Load average is a smoke alarm, not a diagnosis.** It tells you to look, and
then you look at something else.

If your kernel has it — 4.20 and later — there is a better number:

```
ana@vm:~$ cat /proc/pressure/cpu; cat /proc/pressure/io
some avg10=0.00 avg60=0.00 avg300=0.05 total=106470752
full avg10=0.00 avg60=0.00 avg300=0.00 total=0
some avg10=9.49 avg60=16.67 avg300=6.54 total=92820647
full avg10=9.49 avg60=16.65 avg300=6.53 total=92436863
```

**Pressure Stall Information** — PSI — is the percentage of time tasks were
*stalled* waiting for each resource, over ten, sixty and three hundred seconds.
`some` is "at least one task was stalled"; `full` is "everything was".

Those numbers were taken shortly after the disk test above ended: CPU pressure
essentially zero, I/O pressure 16.67% over the last minute. **That is one
reading that says both "not the processor" and "the disk", where the load
average said 1.39 and meant nothing.**

`/proc/pressure/memory` is the third file. If they are missing, the kernel was
built without `CONFIG_PSI`, which some distributions still do.
