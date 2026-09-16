---
title: fork, exec, exit, wait
version: 1
---

There is no system call that means *start a program*. There are two, and they do different halves
of the job. Knowing that explains the process tree, the zombie, the orphan, and why your shell
still exists after the command you ran has finished.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A sequence diagram with two lanes. The parent, bash, calls fork, which creates a child that is a copy of bash. The child calls exec and becomes ls. The parent is blocked in wait until the child calls exit, after which the parent sets the exit status and prints a prompt.\"><defs><marker id=\"lc\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><path d=\"M200 76 L200 286\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M500 118 L500 144\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M500 176 L500 286\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"140\" y=\"44\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bash</text><rect x=\"430\" y=\"88\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">a copy of bash</text><rect x=\"440\" y=\"146\" width=\"120\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"500.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">ls</text><rect x=\"130\" y=\"288\" width=\"140\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"200.0\" y=\"303.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">$? = 0, prompt</text><path d=\"M206 92 L424 100\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc)\"></path><text x=\"350.0\" y=\"86\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">fork()</text><text x=\"500\" y=\"138\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">exec()</text><text x=\"186\" y=\"200\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">wait() — blocked here</text><path d=\"M494 236 L206 244\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc)\"></path><text x=\"350.0\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">exit(0)</text><text x=\"200\" y=\"36\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one process</text><text x=\"500\" y=\"36\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">two processes, one program each</text></svg>", "caption": "Running one command is two system calls, not one. The gap between `fork` and `exec` is where the child changes anything it needs to before the new program loads."}
```

## `fork` makes a copy

A process calls `fork`, and **a second process exists** — a near-identical copy of the first. Same
program, same memory contents, same open files, same working directory. The only difference that
matters is what `fork` returns: the child gets `0`, and the parent gets the child's PID.

That is how each side knows which one it is, and it is the entire mechanism.

## `exec` replaces the program

The child then calls `exec`, which **throws away the program it was running and loads a different
one in the same process.** The PID does not change. The parent does not change. The open files
mostly survive — which is the door section 13's redirections walk through.

So `ls` in your shell is: fork a copy of bash, and have the copy turn into `ls`.

It sounds wasteful and is not: `fork` does not really copy the memory, it marks it to be copied
only if one of the two writes to it. A fork of a program using two gigabytes costs almost nothing
until somebody changes something.

**And the two calls are separate on purpose.** In the gap between them — after the copy exists,
before the new program loads — the child can change its identity, its working directory, its umask
and its open files. **That gap is where a redirection happens**, and where lesson 5's `User=` in a
unit file takes effect. One call that did both would have nowhere to put any of it.

## `exit` and `wait` are also two halves

A process ends by calling `exit` with a number — section 14's exit status. **The number has to go
somewhere**, and where it goes is the parent, which collects it by calling `wait`.

Until the parent collects, the kernel keeps the child's entry in the process table. It has no
memory, no open files and no program: what is left is a PID and a number waiting to be read.
**That is a zombie**, and section 04 makes one on purpose.

So the complete cycle for `ls` in a shell:

1. bash **forks**. Now there are two bashes.
2. The child **execs** `/usr/bin/ls`. Now it is `ls`.
3. bash calls **wait** and blocks — which is why your prompt does not come back.
4. `ls` prints, and **exits** with a status.
5. bash's `wait` returns with that status, puts it in `$?`, and prints a prompt.

**Step 3 is the whole of what `&` changes.** Backgrounding a command means bash does not wait —
section 10.

## When the parent does not wait

Two things can go wrong with step 5, and they have different names and different seriousness.

**The parent is alive and does not collect.** The entry stays. Repeat it a few thousand times and
the process table fills, and the machine cannot start anything at all. That is the leak lesson 5
section 08 attributed to a hand-written container entrypoint.

**The parent exits first.** The child is now an **orphan**, and the kernel hands it to PID 1 — which
is doing nothing but collecting, continuously. Here it is, in one transcript:

```
ana@vm:~/work$ bash -c 'sleep 200 & echo child is $!'
child is 1230
ana@vm:~/work$ ps -eo pid,ppid,stat,comm | grep -E 'PID|sleep' | grep -v grep
  PID  PPID STAT COMMAND
 1230     1 S    sleep
```

The inner `bash` started `sleep` and then exited. `sleep` is still running, and **its PPID is now
`1`** — it was adopted while nobody was looking.

**Orphaning is not an error.** It is how a daemon comes to belong to the system — lesson 5 section
07's second property, and now you have seen it happen.

## What this explains that nothing else does

**Why a child cannot change its parent's directory.** `cd` in a script does not affect the shell
that ran the script, because the script is a separate process with its own copy. `cd` has to be a
shell builtin — lesson 3 section 05 said so, and this is why.

**Why a variable set in a subshell disappears.** `( VAR=1 )` sets it in a copy that then exits.
Lesson 9 comes back to this.

**Why `exec ls` replaces your shell.** Bash has an `exec` builtin that skips the fork: the shell
turns into `ls`, and when `ls` finishes there is no shell to return to. Your terminal closes. Try
it once, in a window you do not mind losing.
