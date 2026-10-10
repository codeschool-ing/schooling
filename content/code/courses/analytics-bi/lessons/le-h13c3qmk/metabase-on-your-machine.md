---
title: Metabase on your machine, and three ways to have it
version: 1
---

**Metabase** is an open-source business intelligence tool: a web application that connects to a
database, lets people build questions by choosing tables, columns and groupings from menus, draws
the answers as charts, and arranges charts into dashboards. It is what lessons 5, 6 and 9 build on,
and the reason it is in this course is that it is free, it runs on your own machine, and what it
does with a semantic layer is what every BI tool does with one.

It runs inside the same virtual machine as PostgreSQL, and you open it in your own browser through
the port forwarded in lesson 1.

## With Docker, in the virtual machine — the recommended path

Metabase is distributed as a **container image**: the program and everything it needs, packaged so
that it runs the same way on any Linux machine with Docker. Install Docker from Ubuntu's own
packages:

```sh
sudo apt update
sudo apt install -y docker.io
```

(The machine this course was recorded on had Docker already, installed from Docker's own packages,
so that step is the one command in this lesson that was not recorded. Everything below was.)

Then start Metabase. The version is written out so that what you see matches the course:

```sh
sudo docker run -d --name metabase --network host --restart unless-stopped \
  -e JAVA_OPTS=-Xmx1g \
  -v metabase-data:/metabase-data -e MB_DB_FILE=/metabase-data/metabase.db \
  metabase/metabase:v0.64.1.5
```

What each part does:

| part | why |
|---|---|
| `-d --name metabase` | run in the background, under a name the other commands can use |
| `--network host` | share the machine's network, so that `localhost:5432` inside Metabase is your PostgreSQL and port 3000 is the machine's |
| `--restart unless-stopped` | start again when the machine reboots |
| `-e JAVA_OPTS=-Xmx1g` | cap the memory Metabase's Java runtime may use, so PostgreSQL keeps room |
| `-v metabase-data:/metabase-data` and `MB_DB_FILE` | keep Metabase's own settings, users and questions in a volume that survives the container |

The first time, Docker downloads the image before starting it and prints its progress. How big it
is, and what is running:

```
ana@vm:~$ sudo docker images metabase/metabase
IMAGE                         ID             DISK USAGE   CONTENT SIZE   EXTRA
metabase/metabase:v0.64.1.5   08b1ebc81765       1.92GB          828MB   U    
```

```
ana@vm:~$ sudo docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES      IMAGE                         STATUS
metabase   metabase/metabase:v0.64.1.5   Up 34 seconds
```

Metabase takes a while to start — about half a minute on the machine this was recorded on, and
more on a small virtual machine. It answers when it is ready:

```
ana@vm:~$ curl -s -w '\n' http://localhost:3000/api/health
{"status":"ok"}
```

**What it costs your machine**, measured once it had settled:

```
ana@vm:~$ sudo docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
NAME       MEM USAGE / LIMIT
metabase   1.412GiB / 15.72GiB
```

About 1.4 GB of memory with the cap in place, which is why lesson 1 asked for a 4 GB machine; the
image takes 1.92 GB of disk.

## The Java file, without Docker

Metabase is also distributed as a single Java file, `metabase.jar`, from its website, run with
`java -jar metabase.jar` on a machine with a recent Java runtime. It needs no Docker, and it is the
natural choice on a computer where Docker is not available. Its own documentation says which Java
version each release needs, and the course does not repeat it, because it changes between releases.

## Online: Metabase Cloud

Metabase sells a hosted version. It costs your machine nothing, and it needs an account, a paid plan
after its trial, and a way for the hosted service to reach your database — which a database inside
your virtual machine does not offer. The course does not depend on it.
