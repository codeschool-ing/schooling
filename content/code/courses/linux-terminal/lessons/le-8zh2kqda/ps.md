---
title: `ps`, and the two dialects it speaks
version: 1
---

`ps` has the strangest option handling of any command in this course, and there is a historical
reason: it accepts **three** syntaxes, from two different ancestries, and they mean different
things.

| | style | example |
|---|---|---|
| **BSD** | no dash | `ps aux` |
| **UNIX** | one dash | `ps -ef` |
| **GNU** | two dashes | `ps --sort=-%cpu` |

**`ps aux` and `ps -ef` are the two you will see**, they print nearly the same thing, and the
difference between them is only which columns and which spelling. Learn one. Recognise the other.

And note what the dash does: **`ps aux` is not `ps -aux`.** The second is the UNIX syntax with `u`
read as a username, and on GNU `ps` it prints a warning and guesses what you meant. Type it without
the dash.

## Plain `ps` shows almost nothing

```
ana@vm:~$ ps
  PID TTY          TIME CMD
 1147 ?        00:00:00 bash
 1148 ?        00:00:00 ps
```

Two processes, because **plain `ps` shows your own processes on this terminal only**. That is
almost never the question, which is why nobody types it.

`ps -f` widens it to the full format for the same set:

```
ana@vm:~$ ps -f
UID        PID  PPID  C STIME TTY          TIME CMD
ana       1147  1145  0 07:19 ?        00:00:00 bash
ana       1150  1147  0 07:19 ?        00:00:00 ps -f
```

## The two you will actually type

```
ana@vm:~$ ps aux | head -4
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0  26536  4240 ?        SLl  06:54   0:03 /process_api --firecracker-init --a
root         2  0.0  0.0      0     0 ?        S    06:54   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?        S    06:54   0:00 [pool_workqueue_release]
```

```
ana@vm:~$ ps -ef | head -4
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 06:54 ?        00:00:03 /process_api --firecracker-init --addr 0.0.0.0:2024 
root         2     0  0 06:54 ?        00:00:00 [kthreadd]
root         3     2  0 06:54 ?        00:00:00 [pool_workqueue_release]
```

Three things before the comparison, because all three are visible above.

**PID 1's command line is cut off**, in both, at a different point. That is not `head`: **`ps`
truncates the last column to your terminal's width** and it does it silently. `ps auxww` — the `w`
twice — turns it off, and it is the difference between reading a process's real arguments and
reading the first eighty of them. The two cuts land differently because the columns in front of them
are different widths.

**The names in square brackets are kernel threads.** `[kthreadd]`,
`[pool_workqueue_release]` — they have no command line at all, so `ps` puts the name in brackets to
say so. There are dozens of them on any Linux machine and they are not your problem.

**And PID 1 here is `process_api`**, not `systemd`, because these transcripts are captured on a
sandbox — the same thing lesson 5 section 77 explained. On a machine that booted normally that first
row says `/sbin/init` or `/lib/systemd/systemd`.

Both commands show every process on the machine. The useful difference:

| | `ps aux` | `ps -ef` |
|---|---|---|
| resource columns | **`%CPU`, `%MEM`, `VSZ`, `RSS`** | no |
| parent PID | no | **`PPID`** |
| state | **`STAT`** | no |

So: **`aux` when you want to know what is using the machine, `-ef` when you want to know who
started what.** That is the whole of choosing between them.

## The columns worth knowing

| | |
|---|---|
| `PID`, `PPID` | the number and its parent — section 87 |
| `USER` | the identity everything is decided by — lesson 4 |
| `STAT` | section 89's letters |
| `%CPU` | **an average since the process started**, not right now |
| `%MEM` | the share of physical memory this process holds |
| `VSZ` | **virtual** size: everything it has mapped, including what it has never touched |
| `RSS` | **resident** set: what is actually in physical memory. The honest number |
| `TTY` | which terminal it is attached to. `?` means **none** — section 76's daemon |
| `TIME` | processor time consumed, cumulative |
| `START`, `ELAPSED` | when it started, and how long ago |
| `COMMAND` / `CMD` | how it was started |

**Three of those mislead people, and it is worth being explicit.**

`%CPU` is a lifetime average. A process that pinned a core for an hour and has been idle since will
show a high number and be doing nothing. For *now*, use `top` — section 92.

`VSZ` is nearly meaningless as a memory figure. A program that maps a two-gigabyte file it never
reads has a two-gigabyte VSZ and uses nothing. **RSS is the number to read**, and even RSS
double-counts shared libraries across processes.

`TTY` of `?` is how you spot a daemon at a glance: no terminal, so nobody is sitting in front of
it.

## Choose your own columns

This is the form worth learning, because it is the one that answers a specific question:

```
ps -eo pid,ppid,user,stat,etime,cmd
```

`-e` is every process, `-o` is the columns you want, and the column names are the ones in the table
above. Add `--sort=` to order by one of them, and a minus sign reverses it:

```
ana@vm:~/work$ ps -eo pid,ppid,user,%cpu,%mem,etime,comm --sort=-%cpu | head -5
  PID  PPID USER     %CPU %MEM     ELAPSED COMMAND
 1463  1461 ana       100  0.0       00:06 runaway.sh
  103    85 root      4.5  2.1       28:09 claude
 1464  1456 root      2.2  0.0       00:00 python3
 1456   103 root      0.2  0.0       00:06 bash
```

**`--sort=-%cpu | head` is the single most useful `ps` there is** — it is "what is eating this
machine", answered in one line. Here the answer is unambiguous: one process at 100% and the next
one at 4.5%. (The three below it are the sandbox these transcripts are captured on, and `runaway.sh`
is section 98's deliberate busy loop.)

`comm` is the program's name; `cmd` or `args` is the whole command line. Use `comm` when you want a
narrow column and `args` when you need to tell two `python3` processes apart.

## `pgrep` when you want the number, not the table

```
ana@vm:~/work$ pgrep -u ana -f sleeper.sh
1426
ana@vm:~/work$ pgrep -a -u ana -f sleeper.sh
1426 /bin/bash ./sleeper.sh
ana@vm:~/work$ pgrep -u ana -f sleeper.sh; echo "pgrep exit: $?"
pgrep exit: 1
```

`pgrep` prints PIDs. `-f` matches against the **full command line** rather than just the program
name, which is how you find a script — because the program is `bash` and the script is an argument.
`-u` narrows to an account. `-a` adds the command line so you can check you matched the right thing.

**And the exit status is the point**: `1` when nothing matched, which makes `pgrep` usable in a
script as a question rather than a source of text to parse.

That last transcript is also the honest way to confirm something is gone. Section 94's `pkill`
takes the same matching options, which is deliberate: **find it with `pgrep`, then run the same
match through `pkill`.**

## The one to stop typing

```
ps aux | grep nginx
```

It works and it has a wart: `grep` finds itself, because `grep nginx` has `nginx` in its own command
line. People fix it with `| grep -v grep`, which is a second wart on top of the first.

`pgrep -a nginx` does the same job, with no self-match and an exit status you can use.
