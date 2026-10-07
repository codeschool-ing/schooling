---
title: It works on my machine
version: 1
---

**A program never runs on its own.** It runs on top of a compiler or an interpreter at some
version, a set of libraries, a database at some other version, and a handful of settings. Every
machine it meets carries its own set of all four, and the bug reports that start with "it works on
my machine" are reports about the difference.

Ana works on `shelf`, the small service that serves a bookshop's catalogue over HTTP. It is written
in Go, so building it needs the Go toolchain, and it keeps its books in PostgreSQL. Her colleague
Bruno looks after another project on the same team that still runs on PostgreSQL 16. The staging
server was set up a year ago by somebody who has since left.

Here is how that goes wrong, concretely. PostgreSQL 17 added `JSON_TABLE`, a way to turn a JSON
document into rows. A report query that uses it runs on a laptop with 17, and fails with a syntax
error on a server with 16. Nobody changed the query. The only thing that differed was the machine.

## The usual answers, and what each costs

**A README that lists versions** is the cheapest and the least reliable. It is a request, nobody
checks it, and it goes stale the first time somebody upgrades one thing for one project.

**Installing everything system-wide** works until two projects disagree. Debian and Ubuntu can
keep PostgreSQL 16 and 17 side by side, on two ports with two data directories. But every tool on the
machine, from `psql` to a backup script, then has to be told which one it means, and the arrangement
is different on every distribution and on every laptop.

**A virtual machine per project** settles the fight, at the price of a whole operating system per
project: its own kernel, its own boot, gigabytes of disk and a fixed slice of memory reserved
whether it is busy or not. Lesson 2 sets the two side by side.

## What a container changes

**A container ships the program together with everything it needs above the kernel**: the
compiler or interpreter, the libraries, the configuration files, at the exact versions somebody
chose. The machine underneath only needs a container engine, and that is the last thing anybody
has to install by hand.

Ana's machine shows it. There is no Go on it at all:

```
ana@vm:~$ env go version
env: ‘go’: No such file or directory
```

And yet she can run the Go compiler, at the version `shelf` needs, without installing it:

```
ana@vm:~$ docker run --rm golang:1.25 go version
go version go1.25.14 linux/amd64
```

`docker run` started a container from the image `golang:1.25`, ran `go version` inside it, and
removed the container when the command ended, which is what `--rm` asks for. The compiler came
with the image. Nothing was installed on Ana's machine, and nothing is left on it apart from the
image itself, which stays for the next run.

The same trick settles Bruno's fight. Two major versions of PostgreSQL, on one machine, one after
the other, and neither installed:

```
ana@vm:~$ docker run --rm postgres:16 postgres --version
postgres (PostgreSQL) 16.15 (Debian 16.15-1.pgdg13+2)
ana@vm:~$ docker run --rm postgres:17 postgres --version
postgres (PostgreSQL) 17.11 (Debian 17.11-1.pgdg13+2)
```

Each image carries its own `postgres` binary and its own libraries. They can run side by side as
well, because each container gets its own filesystem and its own network; lesson 9 runs a real
database that way.

**One honest note about these transcripts.** The first `docker run` of an image on a machine
downloads it, which takes seconds to minutes. The lab had already downloaded these four images,
so no download appears here. Lesson 9 shows one.

## What it does not settle

A container carries everything **above** the kernel and nothing below it. Three things therefore
still depend on the machine, and each has its own lesson:

- **the kernel and the processor.** Every container on a machine shares that machine's kernel, so
  an image built for one processor architecture does not run on another without help. Lesson 2
  shows the error.
- **the data.** A container's files go when the container goes. Lesson 7 shows what is lost, and
  lesson 8 where the data should live instead.
- **the configuration that really differs.** A database password on the laptop and in production
  should not be the same value, so it cannot be baked into the image. Lesson 18 is about passing
  it in when the container starts.
