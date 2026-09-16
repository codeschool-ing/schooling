---
title: Reading the prompt
version: 1
---

The prompt is the first thing on the screen and the last thing anybody explains. It is not
decoration and it is not a logo: **it is a sentence the shell writes, and every part of it answers
a question you would otherwise have to ask.**

```
ana@vm:~$
```

Four pieces, left to right: `ana`, `vm`, `~`, `$`.

## Who, where, and what you are allowed to do

| piece | question it answers | why you care |
|---|---|---|
| `ana` | **who** you are on this machine | permissions follow the user, not the person |
| `vm` | **which machine** this is | the single best defence against running something on the wrong server |
| `~` | **where** you are in the filesystem | every command acts here unless told otherwise |
| `$` | whether you are **root** | `$` is an ordinary user, `#` is the administrator |

The middle two are the ones that save you. When you are connected to four machines in four tabs,
the hostname is what stops you from restarting production because it looked like staging. And the
directory is why `rm *` is a different command in two different places.

## It moves, because it is telling you something

The directory part is live. Watch it change:

```
ana@vm:~$ pwd
/home/ana
ana@vm:~$ cd /etc
ana@vm:/etc$ pwd
/etc
ana@vm:/etc$ cd ~/notes
ana@vm:~/notes$
```

Two things to take from that.

**`~` is your home directory, written short.** The prompt showed `~` and `pwd` answered
`/home/ana`, which is the same place said two ways. When you go somewhere outside your home the
prompt spells the path out — `/etc` — and when you go back inside it, it shortens again:
`~/notes` is `/home/ana/notes`.

**`pwd` and the prompt agree because they are reading the same fact.** If you ever doubt the
prompt, `pwd` is the direct question. Section 01 of lesson 3 goes further into what "current
directory" means; here it is enough that the shell is always in one, and always tells you which.

## The `#` is a warning, not a decoration

```
root@vm:/home/ana# whoami
root
```

`#` instead of `$` means every command you type runs with no restrictions at all. Nothing will
ask you whether you are sure. The system will let you delete the files that make it a system.

This is the whole reason the default prompt bothers to distinguish them, and it is worth training
the reflex now: **look at the last character before you press enter on anything destructive.**
Section 14 explains why you are not root by default, and section 08 of lesson 4 explains `sudo`,
which is how you become root for one command instead of for an evening.

## The shell writes it, so it is yours to change

The prompt is a string in a variable called `PS1`, and it is built from escape codes:

```
ana@vm:~$ echo "$PS1"
${debian_chroot:+($debian_chroot)}\u@\h:\w\$
```

`\u` is the user, `\h` the host, `\w` the working directory, `\$` the `$`-or-`#`. The rest of that
line is Ubuntu being careful about a case you do not have.

You are not expected to write one of these today. What matters is the conclusion: **the prompt is
a decision somebody made, not a property of Linux.** On another machine it may be one character.
It may be green. It may include the time, the git branch, or nothing at all. When you arrive
somewhere and the prompt looks unfamiliar, nothing is wrong — ask the machine directly with
`whoami`, `hostname` and `pwd`, which are the three questions the default prompt was answering for
you.

## When there is no prompt

A prompt means **the shell is ready and waiting for you**. No prompt means it is not.

```
ana@vm:~$ sleep 30
```

Nothing else happens, the cursor sits there, and nothing you type appears to do anything. The
machine has not frozen: a command is running, and the shell will not speak again until it
finishes. That is the normal, healthy state of any command that takes time.

The two questions worth separating, because they have different answers:

- **Is it working, or is it stuck?** You cannot tell from the prompt alone. Lesson 6 gives you
  `ps` and `top`, which are how you actually find out.
- **How do I stop it?** `Ctrl+C`, and the next section but one explains what that key really
  sends and why it is not always enough.

Learning to read this state is most of the difference between somebody comfortable at a terminal
and somebody who reaches for the power button.
