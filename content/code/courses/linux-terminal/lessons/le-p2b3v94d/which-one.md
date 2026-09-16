---
title: Which one, and the answer that is not a personality
version: 1
---

## The three, side by side

| | nano | vim | emacs |
|---|---|---|---|
| **time to be useful** | ten minutes | a few hours | a weekend |
| **installed by default** | nearly always | **always**, as `vi` | never |
| **modes** | no | yes, and it is the point | no |
| **help on the screen** | yes, always | no | partly |
| **how you leave** | `^X` | `:q!` | `C-x C-c` |
| **good at** | one file, one change | text, at speed | being an environment |
| **the case against** | it stops there | the hours | it is not an editor |

## The answer

**Learn nano in ten minutes. Learn four vim commands. Choose later, or never.**

Nano does the job this lesson is about — change a line in a file on a machine
that is somewhere else — completely and immediately. There is no shame in it and
nobody serious thinks there is.

The four vim commands are not optional, because **`vi` is the one that is always
there**: on a rescue image, in a container built from `scratch` plus a shell, on
a machine where somebody removed nano to save four megabytes. `Esc`, `:q!`,
`:wq`, `u`.

Whether you go further into vim is a genuine choice with a real payoff and a real
cost. The payoff is in section 06 — the grammar, and editing at the speed you
think. The cost is the hours, and they are not optional either.

## Two reasons to choose vim that are not aesthetic

**It is on the broken machine.** Everything else is a package that might not be
installed. That is not a small argument when the machine you are fixing is the
one that cannot install packages.

**Its keys are everywhere else.** `less` uses them (lesson 3 section 08). `man`
uses `less`. `git log` uses `less`. `k9s`, `htop`'s search, `psql`, `mysql`, most
file managers, and every IDE's vim mode. `j`, `k`, `/`, `n`, `q` and `G` are the
keys of reading text on Unix, not just of vim.

## Two reasons to choose nano that are not laziness

**You will be right eight times out of ten.** The job is one line in one file,
over `ssh`, at a bad moment. Nano does that, with the keys on the screen, with no
chance of a mode you did not know you were in.

**Somebody else has to read what you write.** A shared machine, a runbook, a
colleague watching your screen. `nano /etc/nginx/nginx.conf` in a document is
followed by anybody; `vim`, then `/server_name`, then `ciw`, is not.

## One reason to choose emacs

You want the environment, and you have decided to spend the time. That is a
legitimate answer and it is not this course's business.

## What is not a reason

**That one of them is for serious people.** They all edit text. Somebody who has
run production systems for fifteen years using nano has not been doing it wrong,
and somebody whose vim configuration is a thousand lines is not necessarily
faster than them.

The argument is about the specific job in front of you, and the specific machine
you are on — which is what the next section is about, because on a great many
days the editor is not something you choose at all.
