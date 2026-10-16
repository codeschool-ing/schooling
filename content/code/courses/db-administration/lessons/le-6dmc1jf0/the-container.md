---
title: The same server in a container
version: 1
---

A container is the second way to have PostgreSQL, and many developers meet it first. It is worth
running once, even though the course does not use it, because what it moves is exactly what this
course is about. **This section is optional**: it needs Docker or Podman on your own computer, not
in the virtual machine, and nothing later depends on it.

The transcripts below were recorded on a laptop with Docker 29.8.2, which is why the prompt says
`ana@laptop`. One command fetches the official image and starts a server from it:

```
ana@laptop:~$ docker run -d --name pg -e POSTGRES_PASSWORD=change-me -v pgdata:/var/lib/postgresql/data -p 127.0.0.1:5433:5432 postgres:16
2cb685fd3eda380157c6e944b893bfcaf55163fa8bd198f7432e4cc9cd4eac0d
ana@laptop:~$ docker ps --format "{{.Names}}  {{.Image}}  {{.Status}}  {{.Ports}}"
pg  postgres:16  Up 6 seconds  127.0.0.1:5433->5432/tcp
```

Every part of that command decides something a package decided for you:

| part | what it decides |
|---|---|
| `postgres:16` | the image, and so the major version. Without the `:16` you get whatever is newest that day |
| `-e POSTGRES_PASSWORD=…` | the password of the `postgres` role. The image refuses to start without one |
| `-v pgdata:/var/lib/postgresql/data` | a **named volume** for the data directory. Leave it out and the data lives inside the container and goes when the container does |
| `-p 127.0.0.1:5433:5432` | which port of your computer reaches the server's 5432, and only from your own computer |

The long line `docker run` printed is the container's id. Ask the server where its files are:

```
ana@laptop:~$ docker exec pg psql -U postgres -c "SHOW data_directory;" -c "SHOW config_file;"
      data_directory      
--------------------------
 /var/lib/postgresql/data
(1 row)

               config_file                
------------------------------------------
 /var/lib/postgresql/data/postgresql.conf
(1 row)
```

Compare that with the package in the previous section. **The configuration file is inside the
data directory**, which is PostgreSQL's own default and not Ubuntu's, and both are inside the
volume. Changing a setting means editing a file in a volume, or passing `-c name=value` arguments
on the `docker run` line, which is how most people do it. And `psql -U postgres` worked with no
password, because inside the container the image trusts connections over the local socket.

The log does not go to a file. It goes to the container's output, and Docker keeps it:

```
ana@laptop:~$ docker logs pg 2>&1 | tail -3
2026-10-10 06:28:20.334 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2026-10-10 06:28:20.336 UTC [63] LOG:  database system was shut down at 2026-10-10 06:28:20 UTC
2026-10-10 06:28:20.339 UTC [1] LOG:  database system is ready to accept connections
```

**Process 1 is the postmaster.** Inside a container there is no systemd: the server is the first
and only program, and when it stops the container stops. The clock is UTC, because the image does
not know where you are.

## What it is good for, and where it stops

A container is the fastest way to get a server you will throw away: a test suite that needs a clean
database on every run, a developer who needs version 16 today and version 17 tomorrow, a bug
report that has to be reproduced exactly. `docker rm -f pg` and `docker volume rm pgdata` remove
every trace of it.

As a production server it asks for things a package gives for free. Upgrading the image is easy;
upgrading the **data** from one major version to the next is not, because the new image cannot read
the old version's files, and lesson 20 is about exactly that problem. Memory, the disk under the
volume and the kernel settings lessons 6 and 9 talk about all belong to the machine the container
runs on, which is one more layer somebody has to look through. None of that makes containers wrong
for databases — many teams run them well — but it is why this course learns the server without the
layer first.
