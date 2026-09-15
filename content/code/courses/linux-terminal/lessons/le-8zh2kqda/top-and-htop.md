---
title: `top`, `htop`, and what the load average actually says
version: 1
---

`ps` is a photograph. **`top` is a film**, and the question it answers is the one you will actually
be asked: what is this machine doing *now*.

It is normally full-screen and interactive, which is no good for a page. `-b` puts it in batch mode
and `-n 1` takes a single frame, so the whole thing comes out as text:

```
ana@vm:~$ top -b -n 1 | head -12
top - 07:23:20 up 28 min,  0 user,  load average: 0.00, 0.01, 0.01
Tasks:  79 total,   1 running,  78 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  16095.9 total,  14859.4 free,    571.8 used,    892.5 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15524.1 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
    1 root      20   0   26536   4240   3844 S   0.0   0.0   0:02.56 process_api
    2 root      20   0       0      0      0 S   0.0   0.0   0:00.01 kthreadd
    3 root      20   0       0      0      0 S   0.0   0.0   0:00.00 pool_workqueue_release
    4 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-rcu_gp
    5 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 kworker/R-sync_wq
```

That is an idle machine: `100.0 id`, one process running, nothing in the list above `0.0`. Worth
seeing once, because **the top five lines are where you look first** and they are easier to read
when there is nothing wrong.

## The five header lines

**Line 1 is `uptime`**, word for word — the time, how long the machine has been up, how many users
are logged in, and three load numbers. The rest of this section is about those three.

**Line 2 counts processes by state**, which is section 89's letters as a tally. `zombie` having its
own number here is the fastest zombie check there is.

**Line 3 is the processors, as percentages**, and the abbreviations matter:

| | |
|---|---|
| `us` | **user** — your programs, doing their own work |
| `sy` | **system** — the kernel, working on their behalf |
| `ni` | user time by processes that were **niced** — section 97 |
| `id` | **idle**. The big number on a healthy machine |
| `wa` | **waiting for I/O**. High here means the disk is the problem, not the processor |
| `st` | **stolen** — a hypervisor gave your time to somebody else's virtual machine |

**`wa` and `st` are the two that tell you something you cannot see anywhere else.** A machine at
`0.5 us` and `60.0 wa` is not busy: it is waiting on storage, and buying a faster processor would
change nothing. A machine with a persistent `st` is on a host that is oversold.

**Lines 4 and 5 are memory**, and `buff/cache` is the number that alarms people for no reason. The
kernel uses spare memory to cache files, gives it back the instant a program wants it, and would be
wasting the memory if it did not. **`avail Mem` on line 5 is the honest figure** — here, 15.5 GiB of
16 available, with 892 MiB in cache that does not count against you.

`free -h` says the same thing in three lines:

```
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       561Mi        14Gi        11Mi       892Mi        15Gi
Swap:             0B          0B          0B
```

**Read the `available` column and ignore `free`.** They differ by the whole of the cache, and
`available` is the one that answers "can I start something big".

## The same machine with one busy loop on it

`runaway.sh` is three lines and does nothing, as slowly as possible:

```
ana@vm:~/work$ cat runaway.sh
#!/bin/bash
# a loop with nothing in it: the shape of a bug that eats a core
while true; do :; done
```

With it running:

```
ana@vm:~$ top -b -n 1 -o %CPU | head -11
top - 07:23:37 up 28 min,  0 user,  load average: 0.08, 0.03, 0.01
Tasks:  81 total,   2 running,  79 sleeping,   0 stopped,   0 zombie
%Cpu(s): 25.0 us,  0.0 sy,  0.0 ni, 75.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  16095.9 total,  14873.3 free,    557.7 used,    892.8 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15538.2 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 1463 ana       20   0    4336   3152   2856 R 100.0   0.0   0:06.56 runaway.sh
    1 root      20   0   26536   4240   3844 S   0.0   0.0   0:02.58 process_api
    2 root      20   0       0      0      0 S   0.0   0.0   0:00.01 kthreadd
    3 root      20   0       0      0      0 S   0.0   0.0   0:00.00 pool_workqueue_release
```

**One process at `100.0` and the machine at `25.0 us`.** Both are true and they are not the same
measurement. This machine has four processors:

```
ana@vm:~$ uptime
 07:23:20 up 28 min,  0 user,  load average: 0.00, 0.01, 0.01
ana@vm:~$ nproc
4
```

**`%CPU` in the process list is a percentage of one processor.** A process can show `400` on a
four-core machine if it is using all of them, and `100` means it has one of them completely. The
`%Cpu(s)` line at the top is a percentage of the *machine*, so one saturated core out of four is
`25.0`. When those two numbers disagree, neither is wrong — divide by `nproc`.

`-o` is the flag worth remembering: `-o %CPU` sorts by processor, `-o %MEM` by memory, and they give
different answers:

```
ana@vm:~$ top -b -n 1 -o %MEM | head -11
top - 07:40:50 up 45 min,  0 user,  load average: 0.46, 0.30, 0.16
Tasks:  79 total,   2 running,  77 sleeping,   0 stopped,   0 zombie
%Cpu(s): 25.0 us,  0.0 sy,  0.0 ni, 75.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  16095.9 total,  14656.7 free,    572.3 used,   1097.1 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15523.6 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
  103 root      20   0 5577356 360368 113084 S  10.0   2.2   1:58.76 claude
   85 root      20   0 1957388  43888  27836 S   0.0   0.3   0:03.27 environment-man
 1924 root      20   0   16420  11528   6228 S   0.0   0.1   0:00.02 python3
 1917 root      20   0    7196   6084   3020 S   0.0   0.0   0:00.02 bash
```

The busy loop is nowhere in sight, because it uses no memory. **"What is using the machine" is two
questions**, and you have to ask both.

## The load average is not a percentage

```
load average: 0.08, 0.03, 0.01
```

Three numbers: the average over **one, five and fifteen minutes**. And what is averaged is not
utilisation — it is **the number of processes that wanted to run**, whether or not a processor was
free. Section 89's `R`, counted over time, plus the ones in `D`.

Which gives you the rule:

**Compare the load to `nproc`.** A load of 4 on four processors is fully busy and fine. A load of 4
on one processor means four things queuing for one, and everything is three times slower than it
should be. The same number is healthy or an emergency depending on a machine you have to look up.

**And read the three together, in order.** `4.10, 1.20, 0.60` is a problem that started just now.
`0.60, 1.20, 4.10` is one that is ending. `4.00, 4.02, 3.98` is a machine that has been like this
for a quarter of an hour, and that is the one to go and look at.

Here is the same busy loop starting, watched through nothing but `uptime`. The loop was started
immediately after the first reading:

```
ana@vm:~$ uptime
 07:43:00 up 48 min,  0 user,  load average: 0.10, 0.20, 0.14
ana@vm:~$ uptime
 07:43:16 up 48 min,  0 user,  load average: 0.30, 0.24, 0.16
ana@vm:~$ uptime
 07:43:39 up 48 min,  0 user,  load average: 0.50, 0.29, 0.18
ana@vm:~$ uptime
 07:44:40 up 49 min,  0 user,  load average: 0.87, 0.45, 0.24
```

**Load is slow.** One core has been fully saturated for the whole of that, so the true answer is
`1.00` from the first second — and after a hundred seconds the one-minute average has reached
`0.87`. It approaches the truth and never quite arrives.

That lag is the point rather than a defect: it smooths out a compiler that runs for two seconds, so
the number means "sustained", not "just now". It also means **the figure you are reading is always a
little behind the machine**, in both directions — a load of 3 on a machine whose problem ended a
minute ago is a load of 3 describing something that is over.

Watch the other two columns as well. Fifteen-minute went `0.14 → 0.24` in the same interval: barely
moved, correctly, because a hundred seconds is a small part of fifteen minutes.

One more thing the load counts that surprises people: **processes in `D`**. A machine with a hung
network filesystem can show a load of 30 with every processor idle, because thirty processes are
stuck in a disk wait. Load is "how many are queuing", and a queue for a disk is still a queue.

## Threads again

```
ana@vm:~$ top -b -n 1 -H -o %CPU | head -11
top - 07:40:52 up 45 min,  0 user,  load average: 0.46, 0.30, 0.16
Threads: 110 total,   2 running, 108 sleeping,   0 stopped,   0 zombie
%Cpu(s): 26.8 us,  0.0 sy,  0.0 ni, 73.2 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  16095.9 total,  14652.8 free,    576.2 used,   1097.1 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15519.7 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 1922 ana       20   0    4336   3148   2852 R  99.9   0.0   0:08.31 runaway.sh
    1 root      20   0   26536   4240   3844 S   0.0   0.0   0:00.84 process_api
   65 root      20   0   26536   4240   3844 S   0.0   0.0   0:00.00 vsock-console
   67 root      20   0   26536   4240   3844 S   0.0   0.0   0:00.65 tokio-rt-worker
```

`-H` shows threads instead of processes, and two things change. The second line now says
`Threads: 110 total` where it said `Tasks: 79` — **thirty-one threads hiding inside seventy-nine
processes**. And PIDs 65 and 67 have the same memory figures as PID 1 and different names:
`vsock-console`, `tokio-rt-worker`. They are threads of process one, which named them.

Section 87 said to ask whether you are counting threads. `-H` is how you ask.

## The keys, when you run it for real

`top` without `-b` is interactive, and six keys cover it:

| | |
|---|---|
| `P` | sort by processor |
| `M` | sort by memory |
| `k` | kill — it asks for a PID and a signal, which is section 94 |
| `u` | filter to one user |
| `1` | show each processor on its own line instead of one average |
| `q` | quit |

**`1` is the one people do not know about.** One average hides the difference between four cores at
25% and one core at 100%, and those are completely different problems.

## `htop`

`htop` is the same job with a better interface: colour, meters, scrolling, a mouse, and a tree view.
It is not installed by default on most systems — `sudo apt install htop`, and lesson 7 is about
that sentence.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 754 397\" role=\"img\" aria-label=\"A captured htop screen with four numbered callouts: the four per-processor meters, the load average beside them, the sorted column header, and the function-key bar along the bottom.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"307\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"54.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"61.00\" y=\"138.00\" width=\"28.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"89.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"103.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"110.00\" y=\"138.00\" width=\"21.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"131.00\" y=\"138.00\" width=\"7.00\" height=\"15.50\" fill=\"var(--term-blue-bg)\"/><rect x=\"40.00\" y=\"153.50\" width=\"315.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"355.00\" y=\"153.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"397.00\" y=\"153.50\" width=\"147.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"544.00\" y=\"153.50\" width=\"196.00\" height=\"15.50\" fill=\"var(--term-green-bg)\"/><rect x=\"40.00\" y=\"169.00\" width=\"665.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"705.00\" y=\"169.00\" width=\"35.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"54.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"110.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"166.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"222.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"278.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"334.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"390.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"446.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"502.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"565.00\" y=\"277.50\" width=\"42.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><rect x=\"607.00\" y=\"277.50\" width=\"133.00\" height=\"15.50\" fill=\"var(--term-cyan-bg)\"/><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40.00\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                                                    </tspan></text><text x=\"40.00\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">  0</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-green)\" textLength=\"294.00\" lengthAdjust=\"spacingAndGlyphs\">||||||||||||||||||||||||||||||||||||100.0%</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\"> </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"49.00\" lengthAdjust=\"spacingAndGlyphs\">Tasks: </tspan><tspan font-weight=\"600\" fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">16</tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">, </tspan><tspan font-weight=\"600\" fill=\"var(--term-green)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">44</tspan><tspan fill=\"var(--term-cyan)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> thr</tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"63.00\" lengthAdjust=\"spacingAndGlyphs\">, 69 kthr</tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">; </tspan><tspan font-weight=\"600\" fill=\"var(--term-green)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">3</tspan><tspan fill=\"var(--term-cyan)\" textLength=\"56.00\" lengthAdjust=\"spacingAndGlyphs\"> running</tspan><tspan fill=\"var(--paper)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">             </tspan></text><text x=\"40.00\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">  1</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-red)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">||</tspan><tspan fill=\"var(--paper)\" textLength=\"252.00\" lengthAdjust=\"spacingAndGlyphs\">                                    </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">2.4%</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\"> </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"98.00\" lengthAdjust=\"spacingAndGlyphs\">Load average: </tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">2.38 </tspan><tspan font-weight=\"600\" fill=\"var(--term-cyan)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">2.29 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">1.67 </tspan><tspan fill=\"var(--paper)\" textLength=\"147.00\" lengthAdjust=\"spacingAndGlyphs\">                     </tspan></text><text x=\"40.00\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">  2</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-green)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">||</tspan><tspan fill=\"var(--paper)\" textLength=\"252.00\" lengthAdjust=\"spacingAndGlyphs\">                                    </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">2.5%</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\"> </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"56.00\" lengthAdjust=\"spacingAndGlyphs\">Uptime: </tspan><tspan font-weight=\"600\" fill=\"var(--term-cyan)\" textLength=\"56.00\" lengthAdjust=\"spacingAndGlyphs\">00:23:15</tspan><tspan fill=\"var(--paper)\" textLength=\"238.00\" lengthAdjust=\"spacingAndGlyphs\">                                  </tspan></text><text x=\"40.00\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">  3</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-green)\" textLength=\"294.00\" lengthAdjust=\"spacingAndGlyphs\">||||||||||||||||||||||||||||||||||||100.0%</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"357.00\" lengthAdjust=\"spacingAndGlyphs\">                                                   </tspan></text><text x=\"40.00\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">Mem</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-green)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">|</tspan><tspan fill=\"var(--term-magenta)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">|</tspan><tspan font-weight=\"600\" fill=\"var(--term-blue)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">|</tspan><tspan fill=\"var(--term-yellow)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">|||</tspan><tspan fill=\"var(--paper)\" textLength=\"182.00\" lengthAdjust=\"spacingAndGlyphs\">                          </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"70.00\" lengthAdjust=\"spacingAndGlyphs\">370M/15.7G</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"357.00\" lengthAdjust=\"spacingAndGlyphs\">                                                   </tspan></text><text x=\"40.00\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">Swp</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--paper)\" textLength=\"259.00\" lengthAdjust=\"spacingAndGlyphs\">                                     </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">0K/0K</tspan><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"357.00\" lengthAdjust=\"spacingAndGlyphs\">                                                   </tspan></text><text x=\"40.00\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                                                    </tspan></text><text x=\"40.00\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">  </tspan><tspan fill=\"var(--term-green)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-black)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">Main</tspan><tspan fill=\"var(--term-green)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\"> </tspan><tspan fill=\"var(--term-blue)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">[</tspan><tspan fill=\"var(--term-black)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">I/O</tspan><tspan fill=\"var(--term-blue)\" textLength=\"7.00\" lengthAdjust=\"spacingAndGlyphs\">]</tspan><tspan fill=\"var(--paper)\" textLength=\"602.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                                      </tspan></text><text x=\"40.00\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-black)\" textLength=\"315.00\" lengthAdjust=\"spacingAndGlyphs\">  PID USER       PRI  NI  VIRT   RES   SHR S </tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\"> CPU%\u25bd</tspan><tspan fill=\"var(--term-black)\" textLength=\"147.00\" lengthAdjust=\"spacingAndGlyphs\">MEM%   TIME+  Command</tspan><tspan fill=\"var(--paper)\" textLength=\"196.00\" lengthAdjust=\"spacingAndGlyphs\">                            </tspan></text><text x=\"40.00\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-black)\" textLength=\"665.00\" lengthAdjust=\"spacingAndGlyphs\"> 2396 ana         20   0  4764  3396  3084 R  98.8  0.0  6:57.70 /bin/bash /home/ana/runaway.sh</tspan><tspan fill=\"var(--paper)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\">     </tspan></text><text x=\"40.00\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\"> 2397 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 4</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">764 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">432 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">120 </tspan><tspan fill=\"var(--term-green)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">R </tspan><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\"> 98.8 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"35.00\" lengthAdjust=\"spacingAndGlyphs\"> 0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 6:57.84 /bin/bash /home/ana/runaway.sh     </tspan></text><text x=\"40.00\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\"> 2605 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">136 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 2</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">036 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 1</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">916 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">S   0.0  0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 0:00.00 sleep 3000                         </tspan></text><text x=\"40.00\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\"> 2606 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">168 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 1</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">952 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 1</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">820 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">S   0.0  0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 0:00.00 tail -f /var/log/wtmp              </tspan></text><text x=\"40.00\" y=\"242.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\"> 2607 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 4</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">764 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">576 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">264 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">S   0.0  0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 0:00.02 bash -c while true; do sleep 5; don</tspan></text><text x=\"40.00\" y=\"258.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\"> 4032 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"77.00\" lengthAdjust=\"spacingAndGlyphs\">ana        </tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\"> 20 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">  0 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 3</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">136 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 2</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">036 </tspan><tspan fill=\"var(--term-cyan)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\"> 1</tspan><tspan fill=\"var(--paper)\" textLength=\"28.00\" lengthAdjust=\"spacingAndGlyphs\">916 </tspan><tspan font-weight=\"600\" fill=\"var(--term-grey)\" textLength=\"91.00\" lengthAdjust=\"spacingAndGlyphs\">S   0.0  0.0 </tspan><tspan fill=\"var(--paper)\" textLength=\"308.00\" lengthAdjust=\"spacingAndGlyphs\"> 0:00.00 sleep 5                            </tspan></text><text x=\"40.00\" y=\"273.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                                                    </tspan></text><text x=\"40.00\" y=\"289.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F1</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Help  </tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F2</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Setup </tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F3</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Search</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F4</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Filter</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F5</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Tree  </tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F6</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">SortBy</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F7</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Nice -</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F8</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Nice +</tspan><tspan fill=\"var(--paper)\" textLength=\"14.00\" lengthAdjust=\"spacingAndGlyphs\">F9</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Kill  </tspan><tspan fill=\"var(--paper)\" textLength=\"21.00\" lengthAdjust=\"spacingAndGlyphs\">F10</tspan><tspan fill=\"var(--term-black)\" textLength=\"42.00\" lengthAdjust=\"spacingAndGlyphs\">Quit  </tspan><tspan fill=\"var(--paper)\" textLength=\"133.00\" lengthAdjust=\"spacingAndGlyphs\">                   </tspan></text></g><text x=\"13.00\" y=\"41.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"13.00\" y=\"56.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"13.00\" y=\"165.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"13.00\" y=\"289.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"13.00\" y=\"345.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"30.00\" y=\"345.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one bar per processor, and this machine has four</text><text x=\"13.00\" y=\"361.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"30.00\" y=\"361.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the load average is an average; the meters beside it are instant</text><text x=\"13.00\" y=\"377.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"30.00\" y=\"377.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the column with the arrow is the one it is sorted by \u2014 F6 changes it</text><text x=\"13.00\" y=\"393.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"30.00\" y=\"393.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">F5 draws the list as a tree; F9 sends a signal you pick from a menu</text></svg>", "caption": "An `htop` screen, captured while the two copies of `runaway.sh` from earlier in this section were running on the same four-processor machine. `htop -u ana` filters the list to one user; the meters at the top are the whole machine either way."}
```

That is a picture rather than a fence, and the reason is a real property of the program:
**`htop` paints a terminal, it does not print lines.** There is no output to redirect into a file
and nothing to paste — it was captured by running it under a pseudo-terminal and reading the screen
it had drawn. Everything else in this course you can copy; this you have to run.

Four things it gives you that `top` does not:

**A bar per processor, always.** `top` needs the `1` key; htop starts that way, and the difference
between one busy core and four is visible without asking.

**`F5`, tree view.** Section 91's `pstree`, live and sorted — which is how you find out that the
process eating the machine is a child of something you recognise.

**`F9`, kill with a menu.** It lists the signals by name, which means you send `TERM` because you
chose it rather than `KILL` because it is what you remember. Section 94 is about why that matters.

**`F4`, filter as you type.** The `ps aux | grep` from section 90, without the wart.

**Use `htop` when you are looking, and `top -b` when you are recording.** A shell script, a cron
job, a bug report — those want batch mode, and `top -b -n 1` is the line that produces something you
can paste into a ticket.
