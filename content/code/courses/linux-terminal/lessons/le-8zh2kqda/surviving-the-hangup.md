---
title: What happens when you close the terminal
version: 1
---

You start something long, you close the window, and you come back to find it did not finish. Or you
come back to find it did. **Both happen, and which one you get is decided by a single signal.**

`SIGHUP` — hangup — is section 08's signal number 1, and its name is literally about modems: the
phone line dropped. What it means now is **the terminal this process was attached to has gone
away**.

The chain is short and worth having in order:

1. The terminal closes, or the ssh connection drops.
2. The kernel sends `SIGHUP` to the **session leader** — your shell.
3. Bash, on its way out, sends `SIGHUP` to **its jobs**.
4. The default action for `SIGHUP` is to die.

**Step 3 is the one that is not the kernel, and it is the one you can change.** Bash is choosing to
pass the signal on; everything below is about telling it not to, or putting the job somewhere the
message cannot reach.

## The experiment

Three background jobs, started the same way except for one detail each. Plain, `nohup`, and plain
followed by `disown`:

```
ana@vm:~/work$ ./watcher.sh &
[1] 2868
ana@vm:~/work$ A=$!
ana@vm:~/work$ nohup ./watcher.sh &
[2] 2870
ana@vm:~/work$ nohup: ignoring input and appending output to 'nohup.out'
B=$!
ana@vm:~/work$ ./watcher.sh &
[3] 2872
ana@vm:~/work$ C=$!
ana@vm:~/work$ disown %3
ana@vm:~/work$ echo "plain=$A nohup=$B disowned=$C"
plain=2868 nohup=2870 disowned=2872
ana@vm:~/work$ ps -o pid,ppid,tty,comm -p $A,$B,$C
  PID  PPID TT       COMMAND
 2868  2867 pts/2    watcher.sh
 2870  2867 pts/2    watcher.sh
 2872  2867 pts/2    watcher.sh
```

**Identical**: same parent, same terminal, same program. Now the terminal goes away — a `SIGHUP` to
the shell and the pseudo-terminal closed, which is what closing a window does — and then, from
somewhere else:

```
$ ps -o pid,ppid,tty,stat,comm -p 2868,2870,2872
  PID  PPID TT       STAT COMMAND
 2870     1 ?        S    watcher.sh
 2872     1 ?        S    watcher.sh
```

**Two of the three are still there and one is gone.** `2868`, the plain background job, was killed
by the hangup. `nohup` and `disown` both survived it.

And look at what the survivors became: `PPID` of `1`, because their parent is gone and section 06
adopted them, and a `TT` of `?`, because the terminal they were attached to does not exist. **That
is the exact shape of lesson 5's daemon**, arrived at by accident rather than on purpose.

## The two that worked, and how they differ

**`nohup` makes the process ignore the signal.** It sets `SIGHUP` to ignored and then runs your
command, so the message still arrives and nothing happens. It also redirects output, because a
process whose terminal is gone has nowhere to write:

```
ana@vm:~/work$ nohup ./watcher.sh &
[1] 2857
ana@vm:~/work$ nohup: ignoring input and appending output to 'nohup.out'
P=$!
ana@vm:~/work$ ls -l nohup.out
-rw------- 1 ana ana 0 Sep 15 07:23 nohup.out
ana@vm:~/work$ ps -p $P -o pid,ppid,tty,comm
  PID  PPID TT       COMMAND
 2857  2856 pts/2    watcher.sh
```

That message is `nohup` telling you two things it did: **input is closed** and **output is going to
`nohup.out`** in the current directory. Note the `-rw-------`: lesson 4's umask, applied to a file
`nohup` created for you.

Redirect it yourself and the message does not appear, which is what you want in anything scripted:

```
nohup ./long-job.sh > job.log 2>&1 &
```

**`disown` takes the job off bash's list**, so step 3 never happens — bash does not send a hangup to
a job it has forgotten. Section 10 showed the `jobs` output going empty; this is what that empties
it *for*.

| | |
|---|---|
| `nohup cmd &` | decided **before** starting. Ignores the signal, and redirects output |
| `cmd &` then `disown` | decided **after** starting. Bash never sends the signal |

**So `disown` is the rescue and `nohup` is the plan.** You reach for `disown` when the thing is
already running and you now need to close the window; you type `nohup` when you knew in advance.

One thing `disown` does not do is fix the output. A disowned job still has your terminal as its
stdout, and when that terminal dies, its next write fails. Redirect before you disown, or accept
that anything it prints from then on is gone.

## `setsid`, which is the sharper version

```
setsid ./long-job.sh > job.log 2>&1 &
```

`setsid` starts the process in a **new session** with no controlling terminal at all — so there is
no terminal to hang up and nothing to inherit. That is not a workaround for the signal; it is the
process genuinely not being attached to your login any more, which is what lesson 5 section 07 said
a daemon is.

## What to use instead of all of this

For anything you actually care about, **none of these is the right answer**, and the reason is that
all three depend on the process surviving until the machine reboots and no further:

| | |
|---|---|
| **a systemd unit** | lesson 5. Starts at boot, restarts on failure, logs to the journal |
| **`tmux` or `screen`** | a terminal that does not go away, that you can reattach to |
| **a timer or cron job** | lesson 13, when it is something that should happen on a schedule |

`nohup` and `disown` are for the thing you started ten minutes ago that turned out to take four
hours. **They are a rescue, not an architecture** — and a job that needs to survive a reboot, be
restarted when it crashes, or be found by somebody who is not you needs the first row of that table.

`tmux` deserves the specific recommendation: run it *before* you start the long job on a remote
machine, and the question in this section never comes up. Your connection dropping does not close
the terminal, because the terminal is on the far end and is still there when you reconnect.
