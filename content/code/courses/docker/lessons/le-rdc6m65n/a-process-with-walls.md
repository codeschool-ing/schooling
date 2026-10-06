---
title: A process with walls
version: 1
---

**A container is often pictured as a small virtual machine**: a little computer with its own
operating system, booted inside the big one. That picture is wrong, and it predicts things that
do not happen. There is no boot, no second kernel and no hidden machine. **A container is an
ordinary process on the host, started in a way that limits what it can see and how much it can
use.**

The quickest way to believe it is to look. Ana starts PostgreSQL in a container, in the
background, which is what `-d` (detached) means:

```
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only postgres:17
6e19ca7ee468df3d42d4217746fb90dac8d4bb6928bd3235fb1cb674076a453c
```

The long hexadecimal string is the container's id. `docker ps` lists the containers that are
running, and shortens the id to its first twelve characters:

```
ana@vm:~$ docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED         STATUS         PORTS      NAMES
6e19ca7ee468   postgres:17   "docker-entrypoint.s…"   4 seconds ago   Up 4 seconds   5432/tcp   db
```

Now Ana asks the **host**, not Docker, for its processes named `postgres`:

```
ana@vm:~$ ps -o pid,ppid,uid,cmd -C postgres
  PID  PPID   UID CMD
10912 10887   999 postgres
10981 10912   999 postgres: checkpointer 
10982 10912   999 postgres: background writer 
10984 10912   999 postgres: walwriter 
10985 10912   999 postgres: autovacuum launcher 
10986 10912   999 postgres: logical replication launcher 
```

The database is right there in the host's ordinary process list. It has an ordinary process
number, 10912, and the five lines below it are the helper processes PostgreSQL starts for itself,
each with 10912 as its parent. Nothing about them says "container". `docker top` asks Docker the
same question about the container `db`, and gets the same processes with the same numbers:

```
ana@vm:~$ docker top db -o pid,ppid,uid,args
PID                 PPID                UID                 COMMAND
10912               10887               999                 postgres
10981               10912               999                 postgres: checkpointer
10982               10912               999                 postgres: background writer
10984               10912               999                 postgres: walwriter
10985               10912               999                 postgres: autovacuum launcher
10986               10912               999                 postgres: logical replication launcher
ana@vm:~$ docker exec db id postgres
uid=999(postgres) gid=999(postgres) groups=999(postgres),101(ssl-cert)
```

**The `999` deserves a second look.** Inside the image, 999 is the user called `postgres`, which
the image created when it was built, as `id` shows. On the host, 999 is just a number; whatever
name the host's own `/etc/passwd` gives it, if any, has nothing to do with the database. A user is
a number to the kernel, and each side of the wall reads it through its own list of names. Lesson
14 comes back to this, because it decides what a process inside a container may do to files
outside it.

## The same process, seen from inside

From inside the container, the same `postgres` sees a very different world:

```
ana@vm:~$ docker exec db cat /proc/1/status | grep -E "^(Name|Pid|PPid):"
Name:	postgres
Pid:	1
PPid:	0
```

Inside, it is process **1**, the first process of its own little world, and its parent is 0,
which means "nobody I can see". Outside, it is 10912 with a parent. **Both are true at once**: the
kernel keeps one process and shows it under two numbers, because the container was given its own
**process namespace**. That is one of the walls.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One Linux kernel at the bottom. Above it, the host&#x27;s process list, which includes dockerd, bash and postgres with process number 10912. Part of that list is drawn inside a box labelled container db: in there, the same postgres is process 1 and cannot see dockerd or bash.\"><defs><marker id=\"l1walls-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"250\" width=\"680\" height=\"36\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">one Linux kernel, shared by everything above it</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the host's view: every process</text><rect x=\"40\" y=\"60\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">dockerd</text><rect x=\"190\" y=\"60\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">bash</text><rect x=\"350\" y=\"40\" width=\"340\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"6 4\"></rect><text x=\"366\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">container db</text><text x=\"366\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its own view: only what is inside</text><rect x=\"380\" y=\"100\" width=\"280\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">postgres</text><text x=\"520\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PID 1 inside  ·  PID 10912 on the host</text><text x=\"520\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">+ five helper processes, children of PID 1</text><path d=\"M105 112 L105 248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1walls-ah-wire)\"></path><path d=\"M255 112 L255 248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1walls-ah-wire)\"></path><path d=\"M520 166 L520 180\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M520 232 L520 248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1walls-ah-wire)\"></path><text x=\"180\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">system calls</text></svg>", "caption": "One process, two numbers. The host sees postgres as 10912 among its other processes; inside the container it is process 1, alone. The kernel underneath is the same one."}
```

The walls come in two kinds, and lesson 4 takes each apart:

- **What the process can see** is limited by namespaces. Its own process list, as above, its own
  hostname, its own network interfaces, its own view of the filesystem.
- **How much the process can use** is limited by cgroups: memory, CPU time, the number of
  processes it may start.

A third piece supplies the files. The process sees a filesystem made from the image, and lesson 4
shows how layers of files are stacked to build it.

## What follows from "it is a process"

Three consequences show up in every lesson after this one, so they are worth saying once here:

- **It starts as fast as a process starts.** There is no operating system to boot, so a container
  is ready when its program is ready. Lesson 2 measures it.
- **It lives as long as its main process.** When that process exits, the container stops. A
  container whose program finished its work a second after starting is not broken; it is done.
- **It shares the host's kernel.** Every container on the machine makes its system calls to the
  same kernel. That is where the speed comes from, and also why the walls matter: a process that
  gets past them is on the host. Lesson 21 is about keeping it in.
