---
title: A program is a file; a process is a file that is happening
version: 3
---

`/usr/bin/sleep` is a file. It sits on a disk, it has a size and an owner, and it does nothing —
because files do not do anything. Run it and something else exists:

```
ana@vm:~$ ps -p $$ -o pid,ppid,user,stat,etime,cmd
  PID  PPID USER     STAT     ELAPSED CMD
 1147  1145 ana      Ss         00:01 bash
```

**That is a process.** A number, a parent, an owner, a state, an age, and the command it came
from. The file on the disk is unchanged and could be running a hundred times over.

## The programs this lesson runs

This lesson starts, watches and stops small programs, and they live in lesson 3's `~/work`. Each
one is shown again, with `cat`, in the section that explains it; make them all now by copying this
block into the terminal:

```sh
cd ~/work
cat > runaway.sh <<'END'
#!/bin/bash
# a loop with nothing in it: the shape of a bug that eats a core
while true; do :; done
END
cat > tree-demo.sh <<'END'
#!/bin/bash
# three levels, so pstree has something to draw
sleep 300 &
bash -c 'sleep 300 & sleep 300' &
sleep 300
END
cat > polite.sh <<'END'
#!/bin/bash
trap 'echo "caught TERM, cleaning up"; exit 0' TERM
trap 'echo "caught INT, staying"' INT
echo "running as $$"
while true; do sleep 1; done
END
cat > group-demo.sh <<'END'
#!/bin/bash
# a parent and two children: killing the parent alone leaves the children
sleep 250 &
sleep 250 &
sleep 250
END
cat > stubborn.sh <<'END'
#!/bin/bash
# ignores TERM entirely: the shape of a program that will not shut down
trap '' TERM
echo "running as $$, ignoring TERM"
while true; do sleep 1; done
END
cat > zombie.py <<'END'
#!/usr/bin/env python3
"""Fork a child, let it exit, and never wait for it. The kernel keeps the
child's entry in the process table because nobody has collected its status."""
import os, time

if os.fork() == 0:
    os._exit(0)          # the child is finished immediately
time.sleep(60)           # the parent does not call wait()
END
cat > sleeper.sh <<'END'
#!/bin/bash
# sleeps, a second at a time, until it is stopped
while true; do sleep 1; done
END
cat > watcher.sh <<'END'
#!/bin/bash
# stands in for a program that keeps an eye on something: it waits, and prints nothing
while true; do sleep 1; done
END
chmod +x runaway.sh tree-demo.sh polite.sh group-demo.sh stubborn.sh zombie.py sleeper.sh watcher.sh
```

None of them does anything useful, which is the point: each is the smallest program that behaves
the way a section needs. **Your process numbers will differ from the ones printed here** — a PID is
whatever number was free — so wherever a command below names one, use yours. And when a section
leaves something running, `jobs` lists it and `kill %1` stops it, which section 09 explains.

## What a process owns

| | |
|---|---|
| **a PID** | its number, unique while it lives |
| **a PPID** | its parent's number — section 06 |
| **an identity** | a uid and a set of gids, from lesson 4 |
| **memory** | its own address space, which no other process can reach into |
| **open files** | a numbered table — section 13 |
| **a working directory** | lesson 3 section 03's "here", per process |
| **an environment** | variables it was started with, and passes to its children |
| **a state** | running, sleeping, stopped — section 04 |

Every one of those is readable, from outside, without a special tool. `$FDPID` below is a `tail`
that section 13 starts; to follow along here, start one first, with
`tail -f logs/app.log > /dev/null & FDPID=$!`:

```
ana@vm:~/work$ ls -l /proc/$FDPID/cwd /proc/$FDPID/exe
lrwxrwxrwx 1 ana ana 0 Sep 15 07:23 /proc/1402/cwd -> /home/ana/work
lrwxrwxrwx 1 ana ana 0 Sep 15 07:23 /proc/1402/exe -> /usr/bin/tail
ana@vm:~/work$ cat /proc/$FDPID/cmdline | tr '\0' ' '; echo
tail -f logs/app.log
```

Lesson 3 section 14 said `/proc` has a directory per process and that everything in it is a file.
**This is the payoff.** `exe` is a symlink to the program. `cwd` is a symlink to where it is
running. `cmdline` is how it was started — with null bytes between the arguments, which is why
`tr` is there.

## The PID, and the two things people assume about it

**It is unique while the process lives, and it is reused afterwards.** A machine hands out numbers
in order and wraps around — usually at 4194304 on modern Linux, 32768 on older. So a PID you wrote
down ten minutes ago may now belong to something else, and a script that kills a PID it saved
earlier is a real class of bug.

**PID 1 is special and the rest are not.** Lesson 5 section 08 covered process one. Nothing else
about a number means anything: a low PID means the process started early, and that is all.

```
ps -p $$ -o pid,ppid,user,stat,etime,cmd
```

That is the command at the top of this section. `$$` is your own shell's PID, expanded by the shell. It is the fastest way to ask about yourself,
and you will use it constantly.

## A process belongs to an account, and that is where lesson 4 lands

With `./runaway.sh &` running in `~/work` — section 07 says what it is:

```
ana@vm:~/work$ ps -eo pid,ppid,user,%cpu,%mem,etime,comm --sort=-%cpu | head -5
  PID  PPID USER     %CPU %MEM     ELAPSED COMMAND
 1463  1461 ana       100  0.0       00:06 runaway.sh
  103    85 root      4.5  2.1       28:09 claude
 1464  1456 root      2.2  0.0       00:00 python3
 1456   103 root      0.2  0.0       00:06 bash
```

The `USER` column is not decoration. **Everything a process may do is decided by that identity** —
which files it can open, which processes it can signal, whether `/etc/shadow` is readable. A web
server running as `www-data` is lesson 5 section 07's sentence, and this column is where you see
it.

It also decides what **you** may do to it. You can signal your own processes. Signalling somebody
else's needs root, and section 09 shows the refusal.

## Threads are not this

A process can have several **threads** — separate lines of execution sharing one address space.
They are not separate processes: they share memory, files and identity, and `ps` hides them by
default.

```
ps -eLf          # one line per thread
```

Java, browsers and databases have many. The `Tasks:` count in lesson 5's status block and in
section 07's `top` counts threads, which is why a machine with eighty processes can report several
hundred tasks. **When a count surprises you, ask whether you are counting threads.**

## What is not a process

Two things that look like one and are not, and both turn up in this lesson:

**A kernel thread.** `ps aux` shows names in square brackets:

```
root         2  0.0  0.0      0     0 ?        S    06:54   0:00 [kthreadd]
root         3  0.0  0.0      0     0 ?        S    06:54   0:00 [pool_workqueue_release]
```

The brackets mean there is no command line to print, because there is no program — it is kernel
code with a PID so the scheduler can handle it. It has no memory of its own, which is the `0` in
the VSZ and RSS columns. **You do not manage these.** Killing one is either refused or a very bad
afternoon.

**A zombie.** A process that has finished and is still in the table. Section 04 makes one.
