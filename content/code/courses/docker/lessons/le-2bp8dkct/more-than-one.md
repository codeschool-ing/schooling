---
title: Several versions, several services
version: 1
---

**The same machine can run as many databases as it has memory for, of any versions, side by side,
because each container has its own files, its own process and its own network.** What collides is
only what they share with the host: a published port number.

## Two major versions at once

Bruno's project still runs on PostgreSQL 16. Ana starts it next to her 17, publishing it on a
different port of her machine, `5416`, while the container inside still listens on `5432` as
always:

```
ana@vm:~$ docker run -d --name db16 -e POSTGRES_PASSWORD=lab-only -p 127.0.0.1:5416:5432 postgres:16
cd90df83b28d88c27422cef4f3499de82d36caf8fdda0bcd2155fe0a808976f1
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -p 5416 -U postgres -tAc "SHOW server_version"
16.15 (Debian 16.15-1.pgdg13+2)
ana@vm:~$ PGPASSWORD=lab-only psql -h 127.0.0.1 -p 5432 -U postgres -d shelf -tAc "SHOW server_version"
17.11 (Debian 17.11-1.pgdg13+2)
```

**Two servers, two versions, two ports on the host, and nothing installed.** The left side of
`-p 127.0.0.1:5416:5432` is the host's port and must be unique on the host; the right side is the
container's and can be the same in every container. Stopping Bruno's project is `docker stop db16`,
and removing it leaves nothing behind except what was put in a volume.

## Not only databases

The same pattern serves anything packaged as an image. A Redis cache is one command, and its own
client, `redis-cli`, is inside the image, so nothing needs installing to talk to it:

```
ana@vm:~$ docker run -d --name cache redis:8
48a173bf17e43525fa86b965b94a1c50b7c02c738b060d968cef4fcf6b0018cb
ana@vm:~$ docker exec cache redis-cli PING
PONG
ana@vm:~$ docker exec cache redis-cli SET opening-hours "Mon-Fri 9-18"
OK
ana@vm:~$ docker exec cache redis-cli GET opening-hours
Mon-Fri 9-18
```

`redis:8` needed no environment variables at all: it starts with no password, listening on its
default port inside the container, and nothing outside can reach it because no port was published.
That is a reasonable default for a throwaway cache on a laptop and the wrong one anywhere else.
**Every image has its own environment variables and its own defaults**, and its page on Docker Hub
lists them. A few that are worth recognising:

| image | the variables its entrypoint reads first |
| --- | --- |
| `postgres` | `POSTGRES_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB` |
| `mariadb` | `MARIADB_ROOT_PASSWORD`, `MARIADB_DATABASE`, `MARIADB_USER`, `MARIADB_PASSWORD` |
| `mongo` | `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD` |
| `redis` | none: configuration is passed as arguments to `redis-server` |

## What "ready in seconds" leaves out

A database started this way is perfect for development, tests and trying things. **For production,
four questions remain open, and the image does not answer them for you**: where the volume's data is
backed up (lesson 8), how much memory the container may use (lesson 17), how the password reaches it
without sitting in a command line (lesson 18), and who applies the security updates to the image
(lesson 20). Many teams answer the first and the last by not running the database in a container at
all, and buying it as a managed service from a cloud provider; that is a fine answer, and it is a
decision, not a default.
