---
title: Absolute and relative, and the slash that decides
version: 1
---

A path is an address. There are exactly two kinds, and **one character tells them apart**:

| | starts with | means | example |
|---|---|---|---|
| **absolute** | `/` | from the root of the tree | `/home/ana/work/src/main.c` |
| **relative** | anything else | from where you are standing | `work/src/main.c` |

That is the whole rule. Everything else in this section is a consequence of it.

## "Where you are standing" is a real thing

Every process on Linux has a **current working directory** — one directory it considers itself to
be in. Your shell has one, and it changes when you `cd`. Ask for it with `pwd`:

```
ana@vm:~$ pwd
/home/ana
ana@vm:~$ cd work
ana@vm:~/work$ pwd
/home/ana/work
ana@vm:~/work$ cd src
ana@vm:~/work/src$ pwd
/home/ana/work/src
```

The prompt is showing you the same fact, shortened — section 06 took that apart. `pwd` is the
direct question, and it is the one to trust when a prompt has been customised into something
unreadable.

**A relative path is resolved against that directory**, by the kernel, at the moment the command
runs. So:

```
ana@vm:~$ cd /home/ana/work/notes
ana@vm:~/work/notes$ ls ../src
main.c  util.c  util.h
```

`../src` meant `/home/ana/work/src` *because of where the shell was*. Typed from somewhere else it
would have meant somewhere else, or nothing at all.

## The same file, four ways

Standing in `/home/ana/work/notes`, every one of these names the same file:

| path | kind | why it works |
|---|---|---|
| `/home/ana/work/src/main.c` | absolute | from the root, spelled out |
| `../src/main.c` | relative | up one, then down |
| `~/work/src/main.c` | absolute, after expansion | `~` becomes `/home/ana` before the command runs |
| `../../ana/work/src/main.c` | relative | silly, and correct |

The last one is there to make a point: **a path does not have to be the shortest route, only a
valid one.** Going up two and back down three is exactly as correct as going up one — the kernel
walks whatever you hand it.

## When to use which

The question is not style. It is: **what happens if this line runs from somewhere else?**

**Use absolute when the answer must not depend on where you are.** Scripts, cron jobs, systemd
units, configuration files, anything another person will run, anything that runs unattended. A
cron job starts in a directory you did not choose, and `logs/app.log` in a cron job is a bug
waiting for a bad night.

**Use relative when the answer *should* depend on where you are.** Working by hand inside a
project, moving a tree that must keep its internal shape, writing a `Makefile` meant to work from
the project's root wherever somebody cloned it.

There is one more reason to prefer absolute in anything written down, and it is not about
correctness: **an absolute path can be read by somebody who is not there.** `/var/log/nginx/`
tells a colleague everything. `../../logs/` tells them nothing unless they can also see your
prompt.

## Where this bites

### The same command, two different meanings

This is the one that costs people an afternoon:

```
rm -r build
```

Typed in `/home/ana/work`, it removes your build directory. Typed in `/`, it tries to remove
`/build`. **Nothing in the command says which** — the missing slash means "here", and "here" moved.
The fix is a habit: before anything destructive with a relative path, `pwd`.

### A path in a file is not resolved where the file is

A configuration file at `/etc/myapp/conf` that says `logs/app.log` does **not** mean
`/etc/myapp/logs/app.log`. It means whatever the program's working directory turns out to be when
it starts, which is usually `/`. This surprises everybody once, and the surprise is always the
same: the file appeared, just not where anybody looked.

**In a configuration file, write the path out in full.** Always.

### `./` in front of a command is not decoration

```
ana@vm:~/work$ ./ledger data/report.csv
```

Running a program in the current directory needs `./` in front of it. That is not about paths
being relative — it is that the shell only searches `$PATH` for a *bare* name, and `.` is not in
`$PATH`. Adding `./` turns the bare name into a path, and a path is not searched for. Lesson 9's
section on `$PATH` is the full story; the habit to build now is that `./something` means *this
one, right here*.

### Windows says the same thing differently

| | Linux | Windows |
|---|---|---|
| separator | `/` | `\` |
| absolute | `/home/ana/notes.txt` | `C:\Users\ana\notes.txt` |
| relative | `notes.txt`, `../notes.txt` | `notes.txt`, `..\notes.txt` |
| one root? | yes, always `/` | one per drive letter |

The idea is identical: with a leading root, from the top; without it, from here. What differs is
that on Windows an absolute path must also say *which tree* — the drive letter — and on Linux
there is only one tree to be at the top of.
