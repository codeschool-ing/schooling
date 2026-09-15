---
title: The tree, and what happens when a parent dies
version: 1
---

Every process except PID 1 has a parent, so the processes on a machine are not a list — they are a
**tree**, with process one at the root.

`pstree` draws it. Here is a small one, made on purpose:

```
ana@vm:~/work$ cat tree-demo.sh
#!/bin/bash
# three levels, so pstree has something to draw
sleep 300 &
bash -c 'sleep 300 & sleep 300' &
sleep 300
ana@vm:~/work$ pstree -p 1260
tree-demo.sh(1260)─┬─bash(1262)─┬─sleep(1264)
                   │            └─sleep(1265)
                   ├─sleep(1261)
                   └─sleep(1263)
```

Five processes from three lines of script. `-p` adds the PIDs, which is what makes it useful rather
than decorative. And the same thing as a table:

```
ana@vm:~/work$ ps -eo pid,ppid,stat,etime,comm --sort=pid | grep -E 'PID|tree-demo|sleep' | grep -v grep
  PID  PPID STAT     ELAPSED COMMAND
 1230     1 S          00:22 sleep
 1260  1258 S          00:02 tree-demo.sh
 1261  1260 S          00:02 sleep
 1263  1260 S          00:02 sleep
 1264  1262 S          00:02 sleep
 1265  1262 S          00:02 sleep
```

**The `PPID` column is the tree**, written down. `pstree` is that column, drawn.

The first row is not part of the demo and it is left in on purpose: `1230` has a `PPID` of `1`,
which means its parent is gone. It is a leftover from the section below, still running twenty
seconds later, and it is the thing that section is about.

## Why the tree matters in practice

**Killing a parent does not kill its children.** That is the single most common wrong assumption in
this lesson. A signal goes to one process; children are separate processes and carry on. Section 94
is about the two ways to reach a whole group.

**A service is a subtree.** Lesson 5 section 79's `CGroup:` block was this shape — the service and
everything it started. That is what systemd tracks, and it is why `systemctl stop` catches
processes that a PID file would have missed.

**And the tree tells you who to blame.** A process doing something surprising has a parent, and the
parent usually explains it. `ps -ef` gives you `PPID`; follow it up until you reach something you
recognise.

## When the parent dies first

Section 88 showed it and it is worth the second look, because the result is not what people expect:

```
ana@vm:~/work$ bash -c 'sleep 200 & echo child is $!'
child is 1230
ana@vm:~/work$ ps -eo pid,ppid,stat,comm | grep -E 'PID|sleep' | grep -v grep
  PID  PPID STAT COMMAND
 1230     1 S    sleep
```

The inner `bash` is gone. `sleep` is not, and its parent is now `1`.

**The child is not killed. It is adopted.** The kernel re-parents an orphan to process one — which
is the one process guaranteed to still be there, and which collects exit statuses continuously
(lesson 5 section 77).

Two consequences you will meet:

**A PPID of 1 means the original parent is gone.** On a normal machine that is either a daemon
(started that way on purpose) or something that outlived whoever started it. `ps -ef | awk '$3==1'`
lists them.

**Closing a terminal does not necessarily stop what you started in it.** The shell dies, the child
is adopted, and it keeps going. Whether that happens depends on the hangup signal in section 96 —
which is a different mechanism from re-parenting, and the two get confused constantly.

## Reading a real tree

`pstree` with no arguments draws the whole machine. Here is this one, unedited:

```
ana@vm:~/work$ pstree
process_api─┬─4
            ├─sh───environment-man─┬─claude─┬─bash───python3───bash───pstree
            │                      │        └─12*[{claude}]
            │                      └─9*[{environment-man}]
            └─10*[{process_api}]
```

That is not the tree of a server, and it is worth saying what it is rather than tidying it away.
**The transcripts in this course are made on a sandbox**, and this is what a sandbox looks like from
the inside: a supervisor at PID 1, the tooling that drives it, and — at the end of the chain — the
shell that ran `pstree`. On a machine that booted normally you would see `systemd` at the root and
a dozen services hanging off it instead.

Four things to read out of any `pstree`, and all four are in that output:

**The root is whatever PID 1 is.** Here it is `process_api`, a container supervisor, for the reason
lesson 5 section 77 gave. On a normally booted machine the top line says `systemd`.

**`N*[name]`** means N identical children, collapsed into one entry. `10*[{process_api}]` is ten,
not one.

**`{name}` in braces** means a **thread**, not a process — section 87's threads. So
`10*[{process_api}]` is one process with ten threads, and in `ps` it is a single row. Three of the
processes here are multi-threaded and it costs three lines to say so.

**And the last chain is you.** `bash───python3───bash───pstree` is the command being read right now,
with everything that started it in front of it. Every `pstree` contains the `pstree`.

A process named `4` is also real, not a rendering artefact: `pstree` prints the kernel's `comm`
field, and nothing stops a program from having a name that looks like a number.

## The two you will want

```
pstree -p           # with PIDs
pstree -u           # showing where the user changes
pstree -p PID       # just this subtree
pstree -s PID       # just this process and its ancestors
```

**`pstree -s PID` is the one worth remembering.** Given a process, it shows the chain upward to PID
1 — which answers "what started this" in one command, without following `PPID` by hand. On a second
run of the same demo:

```
ana@vm:~/work$ pstree -s 1675
process_api───sh───environment-man───claude───bash───runuser───tree-demo.sh───bash───sleep
```

One line, and it reads right to left as an answer: this `sleep` was started by a `bash`, which was
started by `tree-demo.sh`, and so on back to PID 1. The middle of that chain is again this sandbox
rather than a server — but the shape is the point, and the shape is the same everywhere. When
something is running that you did not expect, `pstree -s` on its PID is usually the whole
investigation.

`-u` is the other one worth a mention, because it marks the points where the user changes:

```
ana@vm:~/work$ pstree -up 1670
tree-demo.sh(1670,ana)─┬─bash(1672)─┬─sleep(1674)
                       │            └─sleep(1675)
                       ├─sleep(1671)
                       └─sleep(1673)
```

The name appears once, on `1670`, and not on the children — **`pstree -u` prints a username only
where it differs from the parent's**. A tree with no names in it is a tree that never switched
user; every name in it is a `sudo`, a `su`, or a service dropping privilege the way lesson 5's
`User=` did.
