---
title: The state column, read off a real machine
version: 1
---

Every process is in one of a handful of states, and `ps` prints it in a column called `STAT`. It is
one or two letters, and most people never learn what they mean — which is a shame, because on a
machine that is behaving strangely the state column is usually where the answer is.

Here is the whole of a real machine, counted:

```
ana@vm:~/work$ ps -eo stat --no-headers | sort | uniq -c | sort -rn
     36 S
     24 I<
     15 I
      2 Ss
      2 Sl
      2 SN
      1 Z
      1 SLl
      1 SL
      1 R
```

**Eighty-five processes and one of them is running.** That is not a broken machine — it is a
healthy one. Almost everything on a computer is asleep almost all of the time, waiting for a
keystroke, a packet, a timer or a disk.

## The five states

| | |
|---|---|
| `R` | **running**, or ready to run. It wants the processor |
| `S` | **sleeping**, interruptibly — waiting for something, and a signal can wake it |
| `D` | **uninterruptible sleep** — waiting on the kernel, and a signal will **not** wake it |
| `T` | **stopped** — suspended by a signal, usually `Ctrl+Z`. Section 10 |
| `Z` | **zombie** — finished, and its exit status has not been collected |
| `I` | **idle** kernel thread. Not a problem, and there are a lot of them |

**`R` does not mean "using the processor right now".** It means it is on the run queue — it would
use a processor if one were free. That distinction is the whole of the load average in section 07.

## The extra letters after the state

The second and third characters are flags, and three of them are worth recognising:

| | |
|---|---|
| `s` | it is a **session leader** — usually a login shell or a daemon |
| `l` | it is **multi-threaded** — section 02's threads |
| `<` | high priority, a negative nice value — section 12 |
| `N` | low priority, a positive nice value |
| `+` | it is in the **foreground** of its terminal — section 10 |

So `Ss` is a sleeping session leader, which is what your shell is. `SN` is something sleeping and
politely deprioritised. `I<` is an idle high-priority kernel thread, and there are twenty-four of
them because the kernel keeps a lot of workers around doing nothing.

## `Z` — the zombie, made on purpose

This program forks a child, lets it exit, and never calls `wait`:

```
ana@vm:~/work$ cat zombie.py
#!/usr/bin/env python3
"""Fork a child, let it exit, and never wait for it. The kernel keeps the
child's entry in the process table because nobody has collected its status."""
import os, time

if os.fork() == 0:
    os._exit(0)          # the child is finished immediately
time.sleep(60)           # the parent does not call wait()
```

And here is the result:

```
ana@vm:~/work$ ps -eo pid,ppid,stat,comm,args | grep -E 'zombie|defunct' | grep -v grep
 1173     1 S    zombie.sh       /bin/bash ./zombie.sh
 1197  1192 S    runuser         runuser -u ana -- /home/ana/work/zombie.py
 1199  1197 S    python3         python3 /home/ana/work/zombie.py
 1200  1199 Z    python3         [python3] <defunct>
```

`1200` is the zombie. It is `Z`, it belongs to `1199` — the parent that will not collect it — and
`ps` writes `<defunct>` where a command line would be, in square brackets, because there is no
longer a program to name.

The first row is a different script from an earlier attempt, still running, and it is in the output
only because it has the word `zombie` in its name. **That is what searching processes with `grep`
gets you**: everything whose command line contains the string, related or not. Section 05's `pgrep`
is the version that does not do this to you.

**A zombie is not using anything.** No memory, no processor, no open files. What it occupies is one
entry in the process table and one PID.

**So you do not kill a zombie**, and `kill -9` on one does nothing — you cannot signal something
that has already exited. What you do is one of two things:

- **wait.** When the parent exits, the zombie is re-parented to PID 1, which collects it
  immediately. In the transcript above, the zombie disappeared when the `sleep 60` finished.
- **fix the parent.** A handful of zombies is a program with a bug. Thousands of them is a program
  with a bug and a machine that will soon be unable to start anything.

`ps aux | grep defunct` is how you look for them, and the `Tasks:` line in `top` counts them for
you.

## `D` — the one that means something is wrong

Uninterruptible sleep means the process is inside a kernel call that cannot be stopped partway —
almost always waiting on I/O. **A process in `D` cannot be killed, by anybody, including root, with
any signal.** There is no mechanism: signals are delivered when a process returns to user space,
and it has not.

A moment in `D` is normal — every disk read passes through it. **A process stuck in `D` for
minutes is a symptom**, and the cause is almost always underneath it:

- a network filesystem whose server is not answering;
- a disk that is failing and retrying;
- a device that has gone away while something was using it.

Rebooting is frequently the only way out, and lesson 11 comes back to this when a machine is slow
for reasons `top` cannot show.

## `T` — stopped, and it is waiting for you

A process in `T` has been suspended and is using nothing. `Ctrl+Z` puts your foreground job there,
and section 10 is about getting it back. `kill -STOP` puts any process there, and `kill -CONT`
resumes it.

**A stopped process looks dead and is not.** It holds its memory, its files and its locks, and a
database suspended at the wrong moment will hold a lock nobody else can get. That is why `-STOP` is
a diagnostic tool rather than a way of pausing production.
