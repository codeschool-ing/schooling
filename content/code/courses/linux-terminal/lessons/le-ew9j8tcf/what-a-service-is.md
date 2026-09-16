---
title: A program that outlives your session
version: 1
---

Everything you have run so far started when you typed it and stopped when it finished. A
**service** is the other kind: a program that starts without anybody asking, keeps running when you
log out, and is still there after a reboot.

A web server. A database. The ssh server you used in section 06 — **something had to be listening
before you connected**, and nobody was logged in to start it.

## The older word is *daemon*

You will see both, and they mean the same thing. *Daemon* is the Unix word, and the convention is
that the program's name ends in `d`: `sshd`, `httpd`, `crond`, `systemd`. **The `d` is the word.**

It is not a devil. The name comes from Maxwell's demon in physics — a background agent doing work
nobody is watching — and the spelling is deliberate.

*Service* is the modern word, and it is what `systemctl` calls things. Use whichever the tool in
front of you uses.

## What actually makes a program a daemon

Three properties, and each one is a thing a program has to do deliberately:

**It has no terminal.** Lesson 1 section 03 said a process reads from a terminal and writes to one.
A daemon detaches from any terminal it was started on, which is why closing the window that started
it does not stop it — and why its output has to go somewhere else, which is section 12's whole
subject.

**Its parent is PID 1.** A daemon's original parent exits, and the kernel re-parents the orphan to
process one. Lesson 6 covers re-parenting properly; the visible consequence is that a daemon belongs
to the system rather than to a session.

**It runs as its own account.** Section 02 counted thirty accounts and one person, and this is what
the other twenty-nine are for. A web server running as `www-data` that gets broken into hands the
attacker `www-data`, which can read the site and almost nothing else.

Modern services do not detach by hand any more. **systemd starts them in the foreground and does the
detaching itself** — which is why `Type=simple` in section 11 is the common case, and why a program
written to daemonise the old way needs `Type=forking` to be told so.

## Where a service keeps its things

The same four places every time, and knowing them is most of finding your way around an unfamiliar
one:

| | |
|---|---|
| `/etc/<name>/` | its configuration — text, lesson 3 section 02 |
| `/var/lib/<name>/` | its working data. A database's files live here |
| `/var/log/<name>/` | its logs, if it writes files rather than to the journal |
| `/run/<name>/` | its PID file and its socket, gone at boot |
| `/usr/lib/systemd/system/<name>.service` | how it is started — section 11 |

So: **`nginx` is five paths you can guess before you look.** That is the payoff of lesson 3's
lesson 3 section 02 being a standard rather than a habit.

## Three things a service needs that a command does not

**Something to start it at boot.** That is the whole of sections 08 and 09, and the reason the
`enable` verb exists separately from `start`.

**Somewhere for its output to go.** A command prints to your terminal. A daemon has none, so every
line it writes has to be collected by something — a log file, or the journal in section 12.

**Something to notice when it dies.** A command that crashes leaves you an exit status to look at.
A daemon that crashes at three in the morning leaves nothing, unless whatever started it was
watching. `Restart=on-failure` in section 11 is that, in one line.

Those three needs are exactly what an init system provides, and they are why one exists at all.

## Not everything running is a service

A machine has three kinds of long-running process, and they are managed differently:

| | started by | example |
|---|---|---|
| **a service** | the init system, at boot | `sshd`, `nginx` |
| **a scheduled job** | cron or a timer, at a time | a nightly backup — lesson 13 |
| **a user's background job** | you, from a shell | `tail -f &` — lesson 6 |

The third disappears when your session ends, unless you take steps — lesson 6 section 11 is about
exactly that, and it is the difference between a thing that survives your ssh dropping and a thing
that does not.

**When somebody says "it stopped working when I logged out", the answer is that it was never a
service.** It was the third row, running in a session that ended.
