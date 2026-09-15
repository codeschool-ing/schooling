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
{"svg": "<svg viewBox=\"0 0 720 388\" role=\"img\" aria-label=\"A drawing of an htop screen with four numbered callouts: the per-processor meters at the top left, the task and load summary at the top right, the sorted column header, and the function-key bar along the bottom.\"><rect x=\"20\" y=\"16\" width=\"680\" height=\"218\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"34.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"52\" y=\"34.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  0[||||||||||||||||||||||||        78.4%]  Tasks: 84, 210 thr; 2 running</text><text x=\"52\" y=\"49.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  1[||                               9.1%]  Load average: 1.42 0.98 0.71</text><text x=\"52\" y=\"65.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  2[|                                2.0%]  Uptime: 6 days, 04:11:52</text><text x=\"52\" y=\"80.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  3[|||||||||||||                   41.3%]</text><text x=\"36\" y=\"96.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"52\" y=\"96.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor-dim)\">Mem[|||||||||||||||||           5.20G/15.7G]</text><text x=\"52\" y=\"111.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor-dim)\">Swp[|                            128M/2.00G]</text><text x=\"36\" y=\"142.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"52\" y=\"142.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">  PID USER      PRI  NI  VIRT   RES   SHR S CPU%&lt;MEM%   TIME+  Command</text><text x=\"52\" y=\"158.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\"> 2841 www-data   20   0 1284M  318M 24312 R  78.4  2.0  4:12.87 nginx: worker</text><text x=\"52\" y=\"173.5\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\"> 1284 www-data   20   0 1284M  318M 24312 S   9.1  2.0  0:51.02 nginx: master</text><text x=\"52\" y=\"189.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">  993 postgres   20   0  412M  102M 88104 S   2.0  0.6  1:07.44 postgres: writer</text><text x=\"36\" y=\"220.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"52\" y=\"220.0\" xml:space=\"preserve\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor-dim)\">F1Help  F2Setup F3Search F4Filter F5Tree  F6SortBy F7Nice- F8Nice+ F9Kill  F10Quit</text><text x=\"40\" y=\"266.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"58\" y=\"266.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one bar per processor, and this machine has four</text><text x=\"40\" y=\"281.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"58\" y=\"281.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tasks counts processes; \"thr\" is threads, and it is the bigger number</text><text x=\"40\" y=\"296.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"58\" y=\"296.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the column with the arrow is the one it is sorted by — F6 changes it</text><text x=\"40\" y=\"311.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"58\" y=\"311.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">F5 draws the list as a tree; F9 sends a signal you pick from a menu</text><text x=\"40\" y=\"332.0\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">drawn, not captured: htop is a full-screen program and its screen cannot be pasted</text></svg>", "caption": "The shape of an `htop` screen. This is a drawing rather than a transcript — htop repaints a whole terminal rather than printing lines, so there is nothing to paste; the numbers here are a plausible web server, not this machine."}
```

The reason that is a drawing and not a transcript is worth a sentence, because it is a real property
of the program: **`htop` paints a terminal, it does not print lines.** There is no output to redirect
into a file and nothing to paste. Everything else in this course you can copy; this you have to run.

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
