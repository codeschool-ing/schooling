---
title: One kernel, many distributions
version: 1
---

**Every container on a machine runs on the host's kernel, whatever distribution its image is
named after.** An image called `debian` does not bring Debian's kernel. It brings Debian's files:
its shell, its libraries, its package manager, its `/etc`. The kernel underneath is the one that
was already running.

`uname -r` prints the release of the running kernel. Ana asks the host, then an Alpine container,
then a Debian one:

```
ana@vm:~$ uname -r
6.18.44-fc-v70
ana@vm:~$ docker run --rm alpine:3.22 uname -r
6.18.44-fc-v70
ana@vm:~$ docker run --rm debian:trixie-slim uname -r
6.18.44-fc-v70
```

Three times the same answer, `6.18.44-fc-v70`, which is the lab machine's own kernel build. Now the
same three are asked which distribution they are, which is written in the file `/etc/os-release`:

```
ana@vm:~$ grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"
ana@vm:~$ docker run --rm alpine:3.22 grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Alpine Linux v3.22"
ana@vm:~$ docker run --rm debian:trixie-slim grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
```

**Three different distributions on one kernel.** The host is Ubuntu 24.04; one container sees an
Alpine filesystem, the other a Debian 13 one. That is what "a Debian image" means: a Debian
userland, running on whatever Linux kernel the host has. It works because the Linux kernel keeps
its interface to programs stable across versions, so a Debian 13 `ls` runs on a kernel Debian 13
never shipped.

## What starting costs

`time` reports how long a command took. Here it times a complete container: created from the
image, started, running `true` (a program that exits at once with success), and removed:

```
ana@vm:~$ time docker run --rm alpine:3.22 true

real	0m0.328s
user	0m0.023s
sys	0m0.014s
```

**About a third of a second, from nothing to finished and cleaned up.** The `real` line is the
wall clock; most of it is Docker's own work of setting the container up, because `true` itself
takes no measurable time. There is no operating system to boot, so there is no boot to wait for.
The number belongs to this machine and this run, and yours will differ.

## What an idle container costs

A container that runs `sleep` does nothing at all for ten minutes. `docker stats` shows what it
uses meanwhile; `--no-stream` asks for one reading instead of a live screen:

```
ana@vm:~$ docker run -d --name idle alpine:3.22 sleep 600
e49019bd143ec6cdeae6b87c0423c182b43ba89b78527d92a30b4f2428d55f92
ana@vm:~$ docker stats --no-stream idle
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT   MEM %     NET I/O    BLOCK I/O   PIDS
e49019bd143e   idle      0.00%     668KiB / 15.72GiB   0.00%     0B / 84B   0B / 0B     1
```

**668KiB of memory and no CPU**, which is what the one `sleep` process costs, because that is all
there is. A virtual machine idling would hold its whole kernel and operating system in memory
while doing nothing; that comparison is the one the lab cannot make, as the previous section said.
The `LIMIT` of 15.72GiB is not a reservation either: with no limit set, it is simply all the
memory the host has, and the container could use any of it. Lesson 17 sets one.
