---
title: Logging in, and which file runs when
version: 1
---

An account is a line in a file. A **session** is what happens when somebody uses it — and the two
are so easy to confuse that the commands for each are different.

## Who is here, right now

```
root@vm:~# who
root@vm:~# w
 23:22:27 up  1:30,  0 user,  load average: 0.00, 0.02, 0.00
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU  WHAT
root@vm:~# last -n 5
wtmp begins Tue Feb 17 02:02:53 2026
```

Three commands, and on this machine all three are empty. **That is a real answer and it is worth
sitting with**, because it is the answer you get on most containers.

`who`, `w` and `last` do not look at processes. They read two files — `/var/run/utmp` for current
sessions and `/var/log/wtmp` for past ones — and **something has to write those files**. `login`
writes them. `sshd` writes them. A shell started by a container runtime, or by a process manager,
or by `docker exec`, does not.

So: there are shells running on this machine, and nobody is logged in. Both facts are true at once,
and they are about different things.

On a machine with real logins the same commands are dense:

| | shows |
|---|---|
| `who` | one line per session: user, terminal, when it started, where from |
| `w` | the same, plus **what each one is running** and how long it has been idle |
| `last` | the history, newest first, from `wtmp` |
| `last -f /var/log/btmp` | the **failed** attempts, which is where you look after a break-in |
| `lastlog` | the last login per account, including the ones that never have |

`w`'s header is `uptime`'s output — machine uptime, session count, load average — and lesson 6
takes that last number apart.

## Login shell against interactive shell, and why it decides what runs

Bash reads different startup files depending on how it was started, and this trips up everybody at
least once.

```
ana@vm:~$ shopt login_shell
login_shell     off
ana@vm:~$ bash -lc 'shopt login_shell'
login_shell     on
ana@vm:~$ bash -c 'shopt login_shell'
login_shell     off
```

Three shells, one machine, and the flag differs. Here is what it selects:

| how the shell started | reads |
|---|---|
| **login shell** — ssh, a console login, `su -`, `bash -l` | `/etc/profile`, then the first of `~/.bash_profile`, `~/.bash_login`, `~/.profile` |
| **interactive, not login** — a new terminal tab, `bash` | `/etc/bash.bashrc`, then `~/.bashrc` |
| **not interactive** — a script, `ssh host 'command'` | neither; only `$BASH_ENV` if it is set |

**That third row is the one that costs an afternoon.** A `PATH` you set in `~/.bashrc` works when
you log in and is absent when a cron job or `ssh host 'somecommand'` runs. The fix is to put it
where the shell will actually look, or not to rely on a shell at all.

On Debian and Ubuntu the two are stitched together deliberately. `~/.profile` contains:

```
ana@vm:~$ head -5 ~/.profile
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.
```

and further down it sources `~/.bashrc` if the shell is interactive. That is why putting things in
`~/.bashrc` usually just works — somebody arranged for it to. It is a convention, not a rule, and
it is why the same dotfiles behave differently on a different distribution.

**The practical division**, and it is worth following:

| | |
|---|---|
| `~/.profile` | environment: `PATH`, `EDITOR`, `LANG`. Things a child process should inherit |
| `~/.bashrc` | interaction: aliases, prompt, shell options. Things only a person needs |

An alias in `~/.profile` does nothing useful. An exported variable in `~/.bashrc` works and gets
re-exported on every new shell, which is harmless and slightly silly.

And `~/.bash_logout` runs when a login shell exits — the place for `clear`, if you like that sort
of thing.

## What a session actually consists of

When `login` or `sshd` accepts you, four things happen, in this order:

1. your **identity** is set — uid, primary group, and the supplementary groups from section 61;
2. a **session** is recorded in `utmp` and `wtmp`;
3. your shell from `/etc/passwd` field 7 is started, as a **login shell**;
4. that shell reads the files above, and prints a prompt.

Each of those can fail on its own, and the failure looks different each time. A wrong shell in
field 7 gets you a connection that closes immediately. A home directory that does not exist gets
you a shell in `/` complaining. A group added while you were logged in is not in step 1 for this
session — which is lesson 4 section 61, stated as a sequence.

## Three questions and the command for each

```
ana@vm:~$ whoami        # which account am I
ana@vm:~$ id            # and which groups count for me
ana@vm:~$ tty           # which terminal is this
```

`tty` prints something like `/dev/pts/1` for a terminal and `not a tty` when the shell's input is a
pipe or a script. That answer is genuinely useful: **it is how a program decides whether a human is
watching** — whether to use colour, whether to ask a question, whether to draw a progress bar.
Lesson 8 comes back to it when a command behaves differently in a pipe than it did on screen.
