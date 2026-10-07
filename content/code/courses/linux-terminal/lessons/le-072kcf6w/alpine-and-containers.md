---
title: Alpine, and why your container behaves oddly
version: 2
---

Every other distribution in this lesson is one you might run a server on. **Alpine is the one you
will meet without choosing it**, because it is what the base image in the tutorial you are
following is built from — and it is the first distribution most people use without knowing they
are using it.

`docker` depends on this course. This section is the part of that dependency that belongs here.

To try what follows, install Docker on the machine from lesson 1 with `sudo apt install docker.io`.
Every command below starts with `sudo`, because talking to Docker is an administrator's act until
lesson 4's groups say otherwise; the first `docker run` of an image downloads it.

## It is small on purpose, and that is the whole design

An Alpine image is a handful of megabytes where a Debian one is a hundred or more. In a container
that matters more than it sounds: an image is pulled by every machine that runs it, stored in
every registry that holds it, and rebuilt every time CI runs. Size is bandwidth and money,
multiplied by a number that keeps growing.

```
ana@vm:~$ sudo docker image ls --format '{{.Repository}}:{{.Tag}}  {{.Size}}' alpine
[sudo] password for ana:
alpine:latest  13MB
ana@vm:~$ sudo docker image ls --format '{{.Repository}}:{{.Tag}}  {{.Size}}' ubuntu
ubuntu:24.04  119MB
```

Alpine gets there by replacing two things that every other distribution in this lesson keeps.

## It replaces the userland — busybox instead of GNU

Lesson 1 said the commands are the userland and that GNU supplies it almost everywhere. Alpine
uses **busybox**: one small program that implements `ls`, `cp`, `grep`, `sed` and a hundred others
as modes of itself.

```
ana@vm:~$ sudo docker run --rm alpine readlink -f /bin/ls
/bin/busybox
ana@vm:~$ sudo docker run --rm alpine sh -c 'ls --help 2>&1 | head -3'
BusyBox v1.37.0 (2026-01-10 15:38:28 UTC) multi-call binary.

Usage: ls [-1AaCxdLHRFplinshrSXvctu] [-w WIDTH] [FILE]...
```

`/bin/ls` is a link to `/bin/busybox`, and so is nearly every other command in the image.

The commands are there and the common uses work. **The extensions do not.** GNU's `ls` has long
options; busybox's mostly does not. GNU's `sed -i` takes a suffix argument differently. `grep -P`
is absent. The result is the shape you should recognise:

> A script that works on your Ubuntu machine fails inside the Alpine container, on a flag,
> and the flag looks like it should exist.

That is not a broken container. It is a smaller `ls`.

**And there is no bash.** `/bin/sh` on Alpine is busybox's `ash`, not bash and not dash. A script
beginning `#!/bin/bash` fails outright, and a script beginning `#!/bin/sh` that uses a bash
feature fails in the confusing way lesson 1 section 02 described. If you need bash in an Alpine
image, you install it.

```
ana@vm:~$ sudo docker run --rm alpine sh -c 'command -v bash; echo "exit=$?"'
exit=127
```

`command -v` prints where a command is and prints nothing when there is none, and `127` is lesson
1's number for "no such command".

## It replaces the C library — musl instead of glibc

This is the one that surprises people, because it fails at a distance from its cause.

Almost every Linux program is linked against **glibc**, the GNU C library. Alpine uses **musl**,
which is smaller and stricter. Most software compiled from source builds fine against either.
**A binary compiled elsewhere against glibc will not run on Alpine** — it starts, finds the
library it was built for missing, and refuses.

`ldd` lists the libraries a program loads, and the two `ls` programs answer differently:

```
ana@vm:~$ sudo docker run --rm alpine ldd /bin/ls
	/lib/ld-musl-x86_64.so.1 (0x7ff65ce41000)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7ff65ce41000)
ana@vm:~$ sudo docker run --rm ubuntu:24.04 ldd /bin/ls
	linux-vdso.so.1 (0x00007f8fbbb1b000)
	libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f8fbbabf000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f8fbb8ac000)
	libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007f8fbb812000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f8fbbb1d000)
```

`ld-musl` against `libc.so.6`: the same command name, two C libraries underneath.

What that looks like in practice: a language runtime that downloads prebuilt native modules
— Python wheels, Node native addons — installs them and then cannot load them, with an error
about a shared object. Nothing in the message says "musl". The fix is to build them in the
container, or to use a `-slim` Debian image instead.

**Which is the real decision.** Alpine for a program that does not care — a Go binary, a shell
script, a small service — and Debian slim for anything dragging prebuilt native code behind it.
The size difference is real; so is the afternoon.

## `apk`, the fifth package manager

| | Alpine | Debian side |
|---|---|---|
| install | `apk add curl` | `apt install curl` |
| remove | `apk del curl` | `apt remove curl` |
| update index | `apk update` | `apt update` |
| upgrade | `apk upgrade` | `apt upgrade` |

The flag you will copy without reading is `--no-cache`: `apk add --no-cache curl` installs without
leaving the package index on disk, which keeps the image small. It is in every Dockerfile example
for exactly that reason.

## What to do when you land in one

Three checks, in order, and they are section 11's reflex applied to a container:

1. `cat /etc/os-release` — `ID=alpine` is the answer.
2. If a command is missing a flag you expect, you are in busybox. Read `command --help`.
3. If a prebuilt binary refuses to start, suspect musl before anything else.

---

**One note about this section, because the course's own rule requires it.** Every transcript in
it was captured by running the command. The `apk` table was not: the machine this was written on
could reach Docker's registry but not Alpine's package mirror, so `apk add` could not run there.
On yours, `sudo docker run -it --rm alpine` gives you an Alpine prompt to try it at.
