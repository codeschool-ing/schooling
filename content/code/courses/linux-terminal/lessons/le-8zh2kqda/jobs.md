---
title: Jobs, and the three keys that move things between foreground and background
version: 1
---

One terminal, several things running. **A job is the shell's word for one command you started** —
possibly a pipeline, possibly a script with children, and always a process group, which is why
section 09's `kill %1` reached all of it.

The whole of job control is three keys and four commands, and it is all in this one transcript:

```
ana@vm:~/work$ sleep 300
^Z

[1]+  Stopped                 sleep 300
ana@vm:~/work$ 
ana@vm:~/work$ jobs
[1]+  Stopped                 sleep 300
ana@vm:~/work$ bg
[1]+ sleep 300 &
ana@vm:~/work$ jobs
[1]+  Running                 sleep 300 &
ana@vm:~/work$ sleep 400 &
[2] 2803
ana@vm:~/work$ jobs -l
[1]-  2802 Running                 sleep 300 &
[2]+  2803 Running                 sleep 400 &
ana@vm:~/work$ kill %1
ana@vm:~/work$ kill %2
[1]-  Terminated              sleep 300
ana@vm:~/work$ jobs
[2]+  Terminated              sleep 400
```

Line by line, because every line of it is a thing worth knowing.

## `Ctrl+Z` stops it

`sleep 300` is running in the **foreground**: it has the terminal, and the prompt is not coming back
until it finishes. `Ctrl+Z` sends `SIGTSTP`, and the shell prints `[1]+ Stopped`.

**Stopped means stopped, not backgrounded.** That is section 04's `T` state — the process is
suspended and using no processor at all. A `sleep` does not care. A download does: it is not
downloading while it is stopped, and people lose an hour to this.

(The bare prompt line after `^Z` is not a typo: the shell prints a fresh one once the job has
stopped, so what lands on screen is the stop message and then your prompt back.)

## `jobs` lists them

```
[1]+  Stopped                 sleep 300
```

`[1]` is the **job number**, which is what `%1` refers to. The `+` marks the *current* job — the one
`fg` and `bg` act on with no argument — and `-` marks the one before it. You can see both in the
`jobs -l` line above.

**`jobs -l` adds the PID**, which is the bridge between this list and everything else in the lesson.
Job numbers are the shell's; PIDs are the kernel's, and only one of them means anything to `ps`.

## `bg` un-stops it, in the background

```
ana@vm:~/work$ bg
[1]+ sleep 300 &
ana@vm:~/work$ jobs
[1]+  Running                 sleep 300 &
```

`bg` sends `SIGCONT` and leaves the job without the terminal. `Stopped` becomes `Running`, and the
prompt is yours. Note that bash echoes the command back with an `&` on the end: that is it telling
you what the job now is.

**`Ctrl+Z` then `bg` is the whole recovery** from having started something in the foreground that you
should have backgrounded. Two keystrokes and two letters.

## `fg` brings it back

```
ana@vm:~/work$ sleep 300 &
[1] 2813
ana@vm:~/work$ jobs
[1]+  Running                 sleep 300 &
ana@vm:~/work$ fg
sleep 300
^C

ana@vm:~/work$ 
ana@vm:~/work$ jobs
```

`fg` gives the job the terminal again — and it prints the command so you know what you just got
back. Now `Ctrl+C` reaches it, because `Ctrl+C` goes to whatever is in the foreground. `jobs` after
it is empty.

**That is the loop to remember**: something is running in the background and you want to stop it
interactively, so `fg` it and then `Ctrl+C`.

Both take a job number: `fg %2`, `bg %2`, `kill %2`. With nothing, they act on the `+` job.

## Starting in the background, with `&`

```
ana@vm:~/work$ sleep 400 &
[2] 2803
```

`&` at the end starts it backgrounded from the beginning. The shell prints the job number and the
PID and returns the prompt immediately — section 03's step 3, skipped: **bash does not `wait`.**

`$!` is that PID, which is how the rest of this lesson got hold of things to signal.

## The three keys

| | | |
|---|---|---|
| `Ctrl+C` | `SIGINT` | stop the foreground job |
| `Ctrl+Z` | `SIGTSTP` | suspend the foreground job |
| `Ctrl+D` | *not a signal* | end of input — which often ends the program |

**`Ctrl+D` is the odd one and it is worth separating.** It is not a signal at all: it tells the
terminal that input has ended, and a program reading input sees end-of-file and usually exits.
That is why `Ctrl+D` closes a shell, ends a `cat` with no arguments, and does nothing at all to a
program that is not reading.

## Two things the shell does that surprise people

**A background job still writes to your terminal.** It is not detached from the screen, only from
the keyboard, so its output lands in the middle of whatever you are typing — section 08's
interleaving. `> out.txt 2>&1` is the fix, and section 11's `nohup` does it for you.

**Exiting with a stopped job gets you a warning, once:**

```
ana@vm:~/work$ sleep 300
^Z

[1]+  Stopped                 sleep 300
ana@vm:~/work$ 
ana@vm:~/work$ exit
exit
There are stopped jobs.
ana@vm:~/work$ exit
exit
```

The first `exit` refuses and says why; the second one goes through, and the stopped job is killed
with it. **The warning exists precisely because a stopped job looks finished** — it printed nothing,
it is using nothing, and you have forgotten it is there.

## `disown`, and what it is not

```
ana@vm:~/work$ sleep 300 &
[1] 2830
ana@vm:~/work$ P=$!
ana@vm:~/work$ jobs
[1]+  Running                 sleep 300 &
ana@vm:~/work$ disown %1
ana@vm:~/work$ jobs
ana@vm:~/work$ ps -p $P -o pid,ppid,stat,comm
  PID  PPID STAT COMMAND
 2830  2829 S    sleep
```

`disown` removes a job from the shell's table. `jobs` no longer lists it — and `ps` shows it running
perfectly happily, still a child of the same shell.

**`disown` changes the shell's bookkeeping, not the process.** It is not detaching, it is not
`nohup`, and it does not survive a closed terminal on its own. What it does is stop the shell from
sending the job a hangup on the way out, which is section 11 and is a different mechanism from
everything on this page.

## Where job control does not exist

**Job control is an interactive-shell feature.** A script has no `jobs`, no `%1`, no `fg`. What it
has is `&` and `wait`:

```
long-thing-one &
long-thing-two &
wait                  # until both are finished
```

That is section 03's `wait`, spelled as a shell builtin, and it is how a script runs two things at
once without losing track of them. `wait $PID` waits for one, and its exit status becomes that
process's — which is section 14.
