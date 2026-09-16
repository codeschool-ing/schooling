---
title: Signals, the only thing you can say to a running process
version: 1
---

You cannot talk to a process. It is a separate program with its own memory, and nothing you type
reaches inside it. What you can do is **send it a signal**: a number, delivered by the kernel, with
no message attached.

That is the whole vocabulary. Every `Ctrl+C`, every `kill`, every `systemctl stop`, every graceful
shutdown on a deploy is one of these numbers arriving.

```
ana@vm:~/work$ kill -l | head -4
 1) SIGHUP       2) SIGINT       3) SIGQUIT      4) SIGILL       5) SIGTRAP
 6) SIGABRT      7) SIGBUS       8) SIGFPE       9) SIGKILL     10) SIGUSR1
11) SIGSEGV     12) SIGUSR2     13) SIGPIPE     14) SIGALRM     15) SIGTERM
16) SIGSTKFLT   17) SIGCHLD     18) SIGCONT     19) SIGSTOP     20) SIGTSTP
```

Sixty-four of them exist. **Eight are worth knowing**, and the rest you will meet by accident.

## The eight

| | | |
|---|---|---|
| `SIGTERM` | 15 | **please stop.** The polite one, and the default |
| `SIGINT` | 2 | **interrupt** — what `Ctrl+C` sends |
| `SIGKILL` | 9 | **stop now.** Cannot be caught, blocked or ignored |
| `SIGSTOP` | 19 | **freeze** — also uncatchable. Section 10's `Ctrl+Z` is its cousin |
| `SIGCONT` | 18 | **carry on** after a stop |
| `SIGHUP` | 1 | the terminal went away — section 11 |
| `SIGQUIT` | 3 | `Ctrl+\`, which stops and writes a core dump |
| `SIGCHLD` | 17 | sent to a **parent** when a child exits. Section 03's `wait` |

Names and numbers are interchangeable, and the shell will convert between them:

```
ana@vm:~/work$ kill -l TERM
15
ana@vm:~/work$ kill -l 9
KILL
```

**Use the names.** `kill -15` and `kill -TERM` do the same thing, and only one of them says what it
means in a script somebody reads a year later.

## What a process can do about it

Three choices, and which ones a process gets depends on the signal:

| | |
|---|---|
| **default** | whatever the signal says — usually "die", for the ones above |
| **catch it** | run a function instead. This is where cleanup lives |
| **ignore it** | nothing happens at all |

**`SIGKILL` and `SIGSTOP` are the exceptions: neither can be caught or ignored.** The kernel handles
them without consulting the process, which is exactly why they exist — a program that could refuse
`KILL` would be a program you could never get rid of.

Everything else is negotiable, and here is a script negotiating. `trap` is bash's way of catching a
signal:

```
ana@vm:~/work$ cat polite.sh
#!/bin/bash
trap 'echo "caught TERM, cleaning up"; exit 0' TERM
trap 'echo "caught INT, staying"' INT
echo "running as $$"
while true; do sleep 1; done
```

It catches two signals and treats them differently: `TERM` is a reason to clean up and leave, `INT`
is a reason to say so and carry on. Running it and signalling it:

```
ana@vm:~/work$ ./polite.sh &
[1] 2103
ana@vm:~/work$ running as 2103
PID=$!
ana@vm:~/work$ kill -INT $PID
ana@vm:~/work$ caught INT, staying
kill -TERM $PID
ana@vm:~/work$ caught TERM, cleaning up
jobs
[1]+  Done                    ./polite.sh
```

**Read the interleaving before the result, because it is real and it looks broken.** A background
job prints whenever it likes, and what you type is echoed wherever the cursor happens to be — so
`kill -TERM $PID` appears with no prompt in front of it, on the line after the job's output. The
terminal is not confused; it is showing two things sharing one screen. Section 10 is about keeping
them apart.

Now the result. `INT` arrived and the script printed and kept running — `jobs` would still list it.
`TERM` arrived and it cleaned up and exited, which is why the job is `Done`.

**`Done` is the important word.** It means the script exited normally, on its own terms, having run
the code it wanted to run first.

Now the same script, with `KILL`:

```
ana@vm:~/work$ ./polite.sh &
[1] 2111
ana@vm:~/work$ running as 2111
PID=$!
ana@vm:~/work$ kill -9 $PID
ana@vm:~/work$ jobs
[1]+  Killed                  ./polite.sh
```

**No output from the trap, and the word is `Killed` instead of `Done`.** The `trap` for `TERM` is
still in that script and it was never consulted, because `kill -9` does not consult. The process was
removed.

That difference — `Done` after a message, versus `Killed` in silence — is the entire argument of
section 09.

## The ones that arrive without anybody sending them

Four of the sixty-four are the kernel telling a process it has done something impossible, and they
are worth recognising because you will see their names in crash reports:

| | |
|---|---|
| `SIGSEGV` | touched memory that is not yours. The segmentation fault |
| `SIGFPE` | an arithmetic fault, classically dividing by zero |
| `SIGILL` | an instruction the processor does not have |
| `SIGBUS` | a badly aligned or vanished memory access |

**These are not something you send.** Seeing one in a log means a program hit a bug, and the
signal is the kernel's report of it rather than the cause.

`SIGPIPE` is the one of these you cause yourself, constantly, and never notice. `yes` prints `y`
forever; `head -2` wants two lines and then leaves:

```
ana@vm:~/work$ yes | head -2; echo "yes exit: ${PIPESTATUS[0]}"
y
y
yes exit: 141
```

**`141` is how a signal shows up in an exit status**: 128 plus the signal's number, and `SIGPIPE` is
13. `yes` did not stop because it was finished — it was killed, by the kernel, for writing into a
pipe with nobody at the other end.

**That is the designed behaviour**, and it is why `| head` on an enormous command returns instantly
instead of waiting. `PIPESTATUS` is there because `$?` would give you `head`'s status, which is 0;
section 14 comes back to it.

## Sending one

`kill` is the command, and the name is bad enough to be worth saying out loud: **`kill` sends a
signal, and most signals do not kill.** `kill -STOP` freezes. `kill -CONT` resumes. `kill -HUP` tells
many daemons to re-read their configuration without stopping.

```
kill PID              # TERM, the default
kill -TERM PID        # the same thing, said out loud
kill -9 PID           # KILL
kill -HUP PID         # reload, for a lot of daemons
kill -0 PID           # send nothing; just test whether you may
```

**`kill -0` is the one nobody knows.** It sends no signal at all and only performs the permission
check, so it answers "does this process exist and may I signal it" with an exit status:

```
ana@vm:~/work$ sleep 300 &
[1] 2178
ana@vm:~/work$ kill -0 $!; echo "exit: $?"
exit: 0
ana@vm:~/work$ kill -0 1; echo "exit: $?"
bash: kill: (1) - Operation not permitted
exit: 1
ana@vm:~/work$ kill -0 99999; echo "exit: $?"
bash: kill: (99999) - No such process
exit: 1
```

Three different answers to three different questions: yes, it exists and it is mine; it exists and
it is not mine; it does not exist. **The two failures have different messages and the same exit
status**, which matters — a script that only checks `$?` cannot tell "gone" from "not allowed", and
those call for opposite responses.

That is also your first look at the refusal. PID 1 belongs to `root` and `ana` may not touch it;
section 09 is the rest of that rule.

Section 09 is the rest of `kill`: which process, how to reach a whole group, and what the refusal
looks like when the process is not yours.
