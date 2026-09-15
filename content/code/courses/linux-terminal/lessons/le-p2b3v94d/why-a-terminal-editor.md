---
title: Five times you do not get to choose
version: 1
---

You have an editor you like. This lesson is not about it, because these five
situations do not ask.

**One: the machine is somewhere else.** You are on it over `ssh` (section 75).
There is no graphical anything, and copying the file down, editing it, and
copying it back is three steps where one will do — and two of those steps are
where the permissions get lost.

**Two: you are root for ninety seconds.** One line in one configuration file,
and then out again. Section 64's argument about `sudo` applies: the shorter that
window is, the better.

**Three: something opened an editor and is waiting for you.**

```sh
git commit          # opens an editor for the message
crontab -e          # opens an editor for your schedule — lesson 13
visudo              # opens an editor, and checks the syntax on the way out
sudoedit /etc/x     # opens an editor, as you, on a root-owned file
systemctl edit x    # opens an editor for a unit override
```

**None of those is a question.** A program has opened *something* and will not
continue until you deal with it, and if you do not know what it opened you are
in the situation the joke is about.

**Four: the machine is broken.** A rescue image, a container with twelve
packages in it, a system that will not boot past `emergency.target`. What is
there is `vi`, because something has to be, and the thing that is always there
is the one somebody decided on in 1976.

**Five: it is faster.** Not for writing a program — for the job you will
actually do, which is *change one line in a file and make sure you did not
change anything else*. Opening an IDE for that is like driving to the end of the
drive.

## What is on this machine

```
ana@vm:~$ ls -l /usr/bin/vi /etc/alternatives/vi
lrwxrwxrwx 1 root root 18 Mar 10  2026 /etc/alternatives/vi -> /usr/bin/vim.basic
lrwxrwxrwx 1 root root 20 Mar 10  2026 /usr/bin/vi -> /etc/alternatives/vi
```

`vi` is not a program here. It is a symlink into the alternatives system from
section 32, pointing at `vim.basic` — so typing `vi` gets you vim, with some
compatibility settings on. On a minimal system it may point at `vim.tiny`, or at
`busybox vi`, and those are genuinely more limited.

| | |
|---|---|
| `vi` | there on **everything**. Usually vim, sometimes a smaller vi |
| `vim` | there on nearly everything |
| `nano` | there on nearly every distribution's default install |
| `emacs` | there when somebody installed it |

**`vi` is the one you can count on.** That is the whole of why this lesson spends
more sections on vim than on anything else, and it is not an endorsement.

## What this lesson does

| | |
|---|---|
| **nano**, in one section | ten minutes, and enough for the job |
| **vim**, in seven | because it is what is there, and because it is one idea |
| **emacs**, in one | honestly, and briefly |
| **which one**, and how to make it your default | the part that outlives all three |

And the screens are real. Each editor was started on a real terminal, the keys
were typed, the screen it drew was captured, and the text rows were **checked
against the file on disk** — so a screen that came out wrong would have been
caught rather than printed. Where the file is not on screen, as in nano's
`Save modified buffer?` prompt, the screen is what nano drew and nothing else.
