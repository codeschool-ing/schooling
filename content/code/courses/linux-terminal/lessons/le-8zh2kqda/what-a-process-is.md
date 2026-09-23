---
title: A program is a file; a process is a file that is happening
version: 2
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

Every one of those is readable, from outside, without a special tool:

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
