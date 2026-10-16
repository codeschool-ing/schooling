---
title: Three databases on a machine of your own
version: 1
---

From the next lesson on, nearly every section shows a command and what the server answered, and
the point of showing the answer is that you run the same command and compare. **The platform runs no
database for you.** You build the lab once, on your own computer, and every exercise in the course
is done there.

The lab is one Linux machine with **Docker Engine** on it and three containers: MongoDB 8.0, Redis 7.4
and Cassandra 5.0, from the official images on Docker Hub. Containers are the right tool here for a
reason specific to this course: three products, each with a cluster mode, means up to six copies of
one server running at once by lesson 15. As packages that would be six configuration directories
and six services to keep apart; as containers it is one command each, and `docker rm -f` puts the
machine back the way it was.

Every transcript in the course was recorded on such a machine, which the lessons call the lab: Ubuntu
24.04, Docker Engine 29, a user called `ana` on a machine called `vm`. Your prompt will carry your own
names. The answers will match apart from the ids the servers generate, addresses inside Docker's
network, and timings, which differ on every run anyway.

## If you took the `docker` course, you already have it

Lesson 5 of `docker` builds exactly this machine, a virtual machine called `vm` with Docker Engine
inside. Start it, open a shell in it, and skip to the next section: the three images are all it is
missing.

## Three ways to have the machine

| | what it is | what it costs |
| --- | --- | --- |
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu 24.04 VM with one command, on Windows, macOS or Linux, with Docker Engine installed inside it | 2 processors, 4 GB of memory and 30 GB of disk while it runs; on your own system, only Multipass itself |
| installed | Docker Desktop on Windows or macOS; Docker Engine straight on a computer that already runs Linux | the same images and the same memory, taken from the computer you use for everything else |
| online | a GitHub Codespace, or Play with Docker, in the browser | nothing on your computer; a monthly allowance of free hours, or a session deleted after a few hours, on terms the company offering it sets and can change |

**The virtual machine is recommended because it is the same shape as the lab.** When your output
differs from a transcript, the difference is then worth reading, not a side effect of the setup.
It also costs nothing to lose: lessons 13, 15 and 18 kill servers on purpose, and a machine you
can delete and make again is the right place to do that.

**Installed works for every lesson.** Docker Desktop runs its own small Linux VM, sized in its
settings; give it at least 4 GB of memory, or the three-node Cassandra cluster of lessons 16 to 19
will not start. On Linux, Docker Engine on your own computer is the lab without the freedom to
throw it away.

**Online is named so you know it exists, not recommended.** A session that is deleted takes your
data with it, and lessons 17 to 19 need about 1.5 GB of memory for Cassandra alone, which not
every free online machine has. No lesson depends on a free tier somebody else can change.

## What the lab weighs

Measured on the lab, so you know what you are agreeing to before you start:

```
ana@vm:~$ docker image ls --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "REPOSITORY|mongo|redis|cassandra"
REPOSITORY:TAG   SIZE
cassandra:5.0    541MB
redis:7.4        182MB
mongo:8.0        1.28GB
```

About 2 GB of disk for the three images, before any data. Memory is the part that matters more,
and the next section measures it with all three running.

## On a Mac with Apple silicon

Multipass makes an `arm64` machine there, and all three official images are published for `arm64`,
so every command works unchanged. The only differences you will see are in lines that name the
architecture.
