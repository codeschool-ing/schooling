---
title: `nice`, and asking for less of the processor
version: 1
---

Every runnable process wants a processor and there are not enough. The scheduler decides, and the
one knob you get is **niceness**: a number from `-20` to `19` that says how willing this process is
to step aside.

The name is the right way round and people get it backwards constantly. **A high nice value is a
nice process** — polite, low priority, yields. A negative one is selfish and demanding.

| | |
|---|---|
| `-20` | as demanding as it gets. Needs root |
| `0` | the default, and what everything you start has |
| `19` | as polite as it gets. Runs when nothing else wants to |

```
ana@vm:~/work$ nice
0
```

`nice` with no arguments prints the niceness you have, which is what everything inherits from your
shell.

## Starting something nicely

```
ana@vm:~/work$ nice -n 15 sleep 120 &
[1] 2890
ana@vm:~/work$ P=$!
ana@vm:~/work$ ps -o pid,ni,pri,comm -p $P
  PID  NI PRI COMMAND
 2890  15   4 sleep
```

`NI` is the niceness you asked for. **`PRI` is what the kernel computed from it**, and the two run
in opposite directions — a high `NI` produces a low `PRI`. You will see both columns in `top`, which
prints them as `NI` and `PR`; read `NI` and ignore `PR`, because `NI` is the number you set.

## Does it actually do anything?

Two copies of section 92's busy loop, pinned to the **same** processor with `taskset` so they have
to share it, one at the default and one at 19:

```
ana@vm:~/work$ taskset -c 0 ./runaway.sh &
ana@vm:~/work$ A=$!
ana@vm:~/work$ taskset -c 0 nice -n 19 ./runaway.sh &
ana@vm:~/work$ B=$!
ana@vm:~/work$ sleep 30
ana@vm:~/work$ ps -o pid,ni,time,comm -p $A,$B
  PID  NI     TIME COMMAND
 3052   0 00:00:31 runaway.sh
 3055  19 00:00:00 runaway.sh
```

**Thirty-one seconds of processor for one of them and under a second for the other.** Both wanted to
run continuously for the whole thirty seconds; the polite one got almost nothing.

That is what niceness buys: `19` is not "a bit slower", it is **"only when nobody else wants it"**.
And note the condition that made it visible — they were competing. On an idle machine, a process at
19 runs at full speed, because stepping aside costs nothing when there is nobody to step aside for.

## Changing your mind: `renice`

```
ana@vm:~/work$ renice -n 19 -p $P
2890 (process ID) old priority 15, new priority 19
ana@vm:~/work$ ps -o pid,ni,comm -p $P
  PID  NI COMMAND
 2890  19 sleep
ana@vm:~/work$ renice -n 5 -p $P
renice: failed to set priority for 2890 (process ID): Permission denied
```

`renice` changes a running process, which is what you want when something is already eating the
machine and you would rather slow it down than kill it.

**And it only goes one way.** 15 → 19 is allowed; 19 → 5 is `Permission denied`, on a process that
belongs to you, from the account that set it in the first place. **Niceness is a ratchet for an
unprivileged user**: you may give priority away and you may not take it back.

Root is not bound by the ratchet, and root is the only one who can go negative at all:

```
ana@vm:~/work$ nice -n -5 true; echo "exit: $?"
nice: cannot set niceness: Permission denied
exit: 0
```

```
root@vm:~# nice -n -5 sleep 60 &
root@vm:~# sleep 1; ps -o pid,ni,pri,comm -p $!
  PID  NI PRI COMMAND
 2978  -5  24 sleep
```

Two things in that pair. **Negative niceness needs root**, because raising your own priority is
taking it from somebody else. And look at `ana`'s exit status: **`0`**. `nice` printed the refusal
and then **ran the command anyway**, at the niceness it already had. A script that relies on `nice`
having worked has to check, because the failure is not in the exit status.

## Where this is actually used

**A backup, an index rebuild, a video encode** — anything you want to finish eventually and never at
the cost of the thing the machine is for:

```
nice -n 19 ./nightly-reindex.sh
```

**Something already hurting.** `top` shows a runaway; `renice -n 19 -p PID` gives you the machine
back without killing the process and losing whatever it has done. Then decide properly.

**Never in a unit file.** systemd has `Nice=` — lesson 5's unit file — and that is where it belongs
for a service, because it survives restarts and a shell command does not.

## What `nice` cannot do

**It does not limit memory.** A process at nice 19 that allocates everything still takes the machine
down. Niceness is about processor time and nothing else.

**It does not help when the problem is I/O.** Section 92's `wa` column: a process stuck waiting on
a disk is not competing for the processor at all, so lowering its priority changes nothing. For
that there is a separate knob:

```
ana@vm:~/work$ ionice
none: prio 0
ana@vm:~/work$ ionice -c 3 -p $$; ionice
idle
```

`ionice -c 3` is the I/O equivalent of nice 19: **idle class**, meaning read and write only when the
disk is otherwise unoccupied. `ionice -c 3 -p PID` applies it to something already running. For a
backup that is making a database slow, this is the one that helps and `nice` is not.

**And it is not a cgroup.** Lesson 5's `CGroup:` line is the real mechanism for "this service may
have at most this much" — actual limits, enforced, on processor and memory together. Niceness is a
preference between things that are competing right now; a cgroup is a ceiling that holds whether
anything is competing or not. Lesson 11 comes back to this.
