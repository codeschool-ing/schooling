---
title: Load average, which is not a percentage and not about the processor
version: 2
---

```
ana@vm:~$ uptime
 13:44:05 up  3:13,  0 user,  load average: 0.68, 0.57, 0.79
ana@vm:~$ cat /proc/loadavg
0.68 0.57 0.79 5/128 11037
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

Lesson 6 section 04 named those two states. **The D is the part that surprises
everyone**, and it is why load average is not a processor metric: a machine with an
idle processor and a saturated disk has a high load average, and a machine using every
core with nothing queued has a load average equal to its core count.

Other Unixes do it differently. On Solaris and the BSDs the load average is the
run queue alone, which makes it a processor number there and not here. If you
learned this on another system, unlearn it for Linux.

## Compare it to the core count

Give the loops two minutes, so that the one-minute average has time to catch up
with them:

```sh
cd ~/work/load
sleep 120
```

```
ana@vm:~$ uptime
 13:46:05 up  3:15,  0 user,  load average: 3.55, 1.71, 1.19
ana@vm:~$ nproc
4
```

That is this machine with four busy loops running. **3.55 on four cores is a
machine fully used and not queueing.** The same 3.55 on a single-core machine
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

Stop the loops and start the writers instead, and give them a minute:

```sh
cd ~/work/load
pkill -f spin.sh
./fill.sh &
sleep 60
```

Here is this machine writing to its disk as fast as it can:

```
ana@vm:~$ uptime
 13:47:05 up  3:16,  0 user,  load average: 2.63, 1.78, 1.25
ana@vm:~$ vmstat 1 3
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 2  2      0 15720020   6984 371684    0    0   137 14442 1053    2  9  2 89  1  0  0
 2  1      0 15719940   6984 371684    0    0     0 1014784 3900 4669  1 10 52 37  1  0
 1  2      0 15719940   6984 371684    0    0     0 453632 1973 2351  0  5 53 41  0  0
```

**Load 2.63 on a four-core machine, and the disk is at 99.8% utilisation.** That
99.8% is `iostat`'s, from section 09 of this lesson; `vmstat` does not carry it.
On the load average alone you would close the ticket. The `b 2` and the `wa 41`
are the real story, and they are read in sections 04 and 09.

It goes the other way too. A machine wedged on a dead network filesystem will
show a load average of 40 with every processor idle, because forty processes are
sitting in `D` waiting for a server that is not answering. Nothing is consuming
anything; nothing is going to finish either.

## What to use instead

**Load average is a smoke alarm, not a diagnosis.** It tells you to look, and
then you look at something else.

If your kernel has it — 4.20 and later — there is a better number. Stop the
writers first, and read it straight after:

```sh
cd ~/work/load
pkill -f fill.sh
```

```
ana@vm:~$ cat /proc/pressure/cpu; cat /proc/pressure/io
some avg10=0.00 avg60=0.08 avg300=0.16 total=449522901
full avg10=0.00 avg60=0.00 avg300=0.00 total=0
some avg10=59.63 avg60=37.54 avg300=12.06 total=146273944
full avg10=57.72 avg60=36.32 avg300=11.65 total=137359071
```

**Pressure Stall Information** — PSI — is the percentage of time tasks were
*stalled* waiting for each resource, over ten, sixty and three hundred seconds.
`some` is "at least one task was stalled"; `full` is "everything was".

Those numbers were taken shortly after the disk test above ended: CPU pressure
essentially zero, I/O pressure 37.54% over the last minute. **That is one
reading that says both "not the processor" and "the disk", where the load
average said 2.63 and meant nothing.**

`/proc/pressure/memory` is the third file. If they are missing, the kernel was
built without `CONFIG_PSI`, which some distributions still do.
