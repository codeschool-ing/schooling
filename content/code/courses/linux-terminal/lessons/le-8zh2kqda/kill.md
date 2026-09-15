---
title: `kill`, and why `-9` is the wrong first move
version: 1
---

Section 93 was what a signal is. This is how to aim one, and there are four ways to name a target:
by PID, by job, by group, and by name. They fail differently and that is the whole of the section.

## By PID

```
kill 1234             # TERM
kill -TERM 1234       # the same, spelled out
kill -9 1234          # KILL
```

Exact and unambiguous, and the answer when you already know the number. `pgrep` from section 90 is
usually how you got it.

**And `kill` needs permission.** You can signal processes that are yours; anything else is refused:

```
ana@vm:~/work$ ps -o pid,user,comm -p 2189
  PID USER     COMMAND
 2189 root     sleep
ana@vm:~/work$ kill 2189; echo "exit: $?"
bash: kill: (2189) - Operation not permitted
exit: 1
ana@vm:~/work$ kill -9 2189; echo "exit: $?"
bash: kill: (2189) - Operation not permitted
exit: 1
```

`-9` is not a bigger hammer for permissions. **The check happens before the signal**, so an
unprivileged `kill -9` on somebody else's process fails in exactly the way the polite one did. Lesson
4's `sudo` is the answer, and it is the answer for `kill -TERM` too.

## By job

In an interactive shell, `%1` means "job one" — and this is where the difference between a process
and a job first bites.

```
ana@vm:~/work$ cat group-demo.sh
#!/bin/bash
# a parent and two children: killing the parent alone leaves the children
sleep 250 &
sleep 250 &
sleep 250
```

Started in the background, the script and its three `sleep` processes look like this:

```
ana@vm:~/work$ ./group-demo.sh &
[1] 2668
ana@vm:~/work$ P=$!
ana@vm:~/work$ ps -o pid,ppid,pgid,comm -p $(pgrep -d, -g $P)
  PID  PPID  PGID COMMAND
 2668  2667  2668 group-demo.sh
 2669  2668  2668 sleep
 2670  2668  2668 sleep
 2671  2668  2668 sleep
```

Four processes, **one `PGID`**. That third column is new: a **process group**, and every process the
script started is in it, because a child inherits its parent's group.

Now `kill $P` — the parent's PID, and nothing else:

```
ana@vm:~/work$ kill $P
ana@vm:~/work$ ps -o pid,ppid,pgid,comm -p $(pgrep -d, -g $P)
  PID  PPID  PGID COMMAND
 2669     1  2668 sleep
 2670     1  2668 sleep
 2671     1  2668 sleep
[1]+  Terminated              ./group-demo.sh
```

**The parent is gone and the three children are not.** Their `PPID` is `1` — section 91's adoption,
happening for real — and their `PGID` is still `2668`, the group of a process that no longer exists.

That is the failure people hit constantly: the thing you killed is dead, the work it started is
still running, and nothing told you.

`%1` does not have this problem:

```
ana@vm:~/work$ ./group-demo.sh &
[1] 2678
ana@vm:~/work$ P=$!
ana@vm:~/work$ kill %1
ana@vm:~/work$ pgrep -g $P; echo "left: $?"
[1]+  Terminated              ./group-demo.sh
left: 1
```

Same script, same four processes, and `pgrep` finds nothing afterwards. **`kill %1` signals the
job's whole process group**, because that is what a job is — bash made the group when it started the
command, and `%1` names the group rather than one process.

So, in an interactive shell: **`kill %1` when you mean "that thing I started", and `kill PID` when
you mean one specific process.** Those two sentences are different and people say the first while
typing the second.

## By group

`%1` only exists in an interactive shell. The form that works anywhere is **a negative number**,
which `kill` reads as a process group rather than a process. Here is the same failure as above and
then the repair, in one go:

```
ana@vm:~/work$ ./group-demo.sh &
[1] 2684
ana@vm:~/work$ P=$!
ana@vm:~/work$ kill $P
ana@vm:~/work$ ps -o pid,ppid,pgid,comm -p $(pgrep -d, -g $P)
  PID  PPID  PGID COMMAND
 2685     1  2684 sleep
 2686     1  2684 sleep
 2687     1  2684 sleep
[1]+  Terminated              ./group-demo.sh
ana@vm:~/work$ kill -- -$P
ana@vm:~/work$ pgrep -g $P; echo "left: $?"
left: 1
```

**`kill -- -2684` signals process group 2684**, and the group outlived the process it was named
after — the leader was killed two lines earlier, and the group is still what finds its members.

The `--` is not decoration. Without it the negative number is read as a **signal**:

```
ana@vm:~/work$ sleep 400 &
[1] 2692
ana@vm:~/work$ P=$!
ana@vm:~/work$ kill -$P; echo "exit: $?"
bash: kill: 2692: invalid signal specification
exit: 1
```

It fails loudly here, which is lucky rather than guaranteed — `kill -9 -2684` has a signal already,
so the group is what the number means, and a mistyped one goes somewhere. `pkill -g 2684` says the
same thing with no negative numbers in it, and is the version to prefer in a script.

So `kill %1` and `kill -- -PGID` are the same idea with different spellings, and the second is the
one that works in cron, in a script, and from another terminal.

## By name

```
ana@vm:~/work$ ./watcher.sh &
[1] 2708
ana@vm:~/work$ ./watcher.sh &
[2] 2710
ana@vm:~/work$ pgrep -a -f watcher.sh
2708 /bin/bash ./watcher.sh
2710 /bin/bash ./watcher.sh
ana@vm:~/work$ pkill -f watcher.sh; echo "pkill exit: $?"
[1]-  Terminated              ./watcher.sh
[2]+  Terminated              ./watcher.sh
pkill exit: 0
ana@vm:~/work$ pgrep -f watcher.sh; echo "pgrep exit: $?"
pgrep exit: 1
```

`pkill` takes section 90's `pgrep` options and sends a signal instead of printing. **`0` when it
matched something and `1` when it did not**, which makes it usable in a script.

`killall` is the other one, and it matches the program's name exactly rather than a pattern:

```
ana@vm:~/work$ ./watcher.sh &
[1] 2716
ana@vm:~/work$ ./watcher.sh &
[2] 2718
ana@vm:~/work$ killall -v watcher.sh
Killed watcher.sh(2716) with signal 15
Killed watcher.sh(2718) with signal 15
[1]-  Terminated              ./watcher.sh
[2]+  Terminated              ./watcher.sh
```

**`-v` is worth typing every time.** It names what it killed, and the whole risk of killing by name
is not knowing what you hit.

Which is this:

```
ana@vm:~/work$ touch watcher.log
ana@vm:~/work$ ./watcher.sh &
[1] 2757
ana@vm:~/work$ tail -f watcher.log &
[2] 2759
ana@vm:~/work$ pgrep -a -f watcher
2757 /bin/bash ./watcher.sh
2759 tail -f watcher.log
ana@vm:~/work$ pkill -f watcher
[1]-  Terminated              ./watcher.sh
[2]+  Terminated              tail -f watcher.log
```

**A `tail` that was only reading a log file was killed**, because `-f` matches the whole command line
and `watcher.log` contains the word. Nothing warned anybody.

So: **run the `pgrep` first, read the list, then change `pgrep` to `pkill`.** They take identical
options for exactly this reason. Section 90 said it from the other side; this is what it prevents.

On a production machine the list is longer, the mistake is `pkill -f java`, and the thing you did not
mean to match was somebody else's service.

## Why not `-9`

`kill -9` is the reflex, and it is the wrong reflex, because **a program cannot clean up after a
`KILL`.** Section 93 showed the trap never running. What that means in practice:

- a database does not flush what it was holding, and the next start is a recovery;
- a lock file, a PID file or a socket is left behind, and the next start refuses;
- a half-written file stays half-written;
- children are not stopped, because the parent never got to stop them.

**`TERM` asks and `KILL` removes.** Almost everything you will ever want to stop handles `TERM`
properly, because handling it is how a program gets to shut down at all.

The rule is to escalate, and give it a moment:

```
ana@vm:~/work$ cat stubborn.sh
#!/bin/bash
# ignores TERM entirely: the shape of a program that will not shut down
trap '' TERM
echo "running as $$, ignoring TERM"
while true; do sleep 1; done
ana@vm:~/work$ ./stubborn.sh &
[1] 2731
ana@vm:~/work$ running as 2731, ignoring TERM
P=$!
ana@vm:~/work$ kill $P
ana@vm:~/work$ kill -0 $P; echo "still there: $?"
still there: 0
ana@vm:~/work$ kill -9 $P
ana@vm:~/work$ kill -0 $P; echo "now: $?"
bash: kill: (2731) - No such process
now: 1
[1]+  Killed                  ./stubborn.sh
```

`trap '' TERM` with an empty handler means **ignore**, and this script ignores it completely — after
the `TERM`, `kill -0` still says `0`. Then `-9`, and it is gone, with `Killed` rather than `Done`.

(The `running as ...` line lands above the `P=$!` you typed, for section 93's reason: the script
printed it the instant it started, and what you type is echoed wherever the cursor is.)

**That sequence is the discipline**: `TERM`, wait a few seconds, check, and only then `-9`. Section
93's `kill -0` is the check, and it costs nothing.

`systemctl stop` does exactly this for you, which is one of the things lesson 5 was buying: `TERM`
to the whole cgroup, wait `TimeoutStopSec`, then `KILL` to whatever is left.

## The summary worth keeping

| | |
|---|---|
| `kill PID` | one process, politely |
| `kill %1` | the job and everything in it |
| `pkill -f pattern` | everything matching — **run `pgrep` first** |
| `killall -v name` | by program name, and say what you hit |
| `kill -- -PGID` | the whole process group, anywhere |
| `kill -0 PID` | is it still there, and may I |
| `kill -9 PID` | last, and only after waiting |
