---
title: Named volumes
version: 1
---

**A named volume is storage that Docker creates and manages, that has a name somebody chose, and
that outlives every container using it.** It is the answer lesson 7 ended on: the database's files
go into the volume, the container becomes disposable, and the next container started with the same
volume finds the data where the last one left it.

## Creating one, and where it lives

```
ana@vm:~$ docker volume create pgdata
pgdata
ana@vm:~$ docker volume inspect pgdata
[
    {
        "CreatedAt": "2026-10-06T16:42:09Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/pgdata/_data",
        "Name": "pgdata",
        "Options": null,
        "Scope": "local"
    }
]
```

`docker volume create` makes an empty volume; `docker run -v pgdata:…` would also have created it
on first use. `inspect` shows its driver, `local`, meaning a directory on this machine, and its
`Mountpoint` under `/var/lib/docker/volumes/`. **That path is Docker's, not yours**: the right way
to reach the data is through a container, never by editing files there, for the reason lesson 6
gave about `/var/lib/docker`.

## The database that survives

Ana runs PostgreSQL with the volume mounted where the image keeps its data, creates the table from
lesson 7 and adds the same row:

```
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17
39c55448bbf0e2f00e98c456eafd9195d36821aac8135ec8116ecec81ba73e57
ana@vm:~$ docker exec db psql -U postgres -c "CREATE TABLE loans (book text, reader text)" -c "INSERT INTO loans VALUES ('Dom Casmurro', 'Bruno')"
CREATE TABLE
INSERT 0 1
```

Then she removes the container and starts a new one, with the same `-v` option:

```
ana@vm:~$ docker rm -f db
db
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17
9b051eb556af2654379438b92ebffd523627fdf53ff9cfa34152ca54c890f593
ana@vm:~$ docker exec db psql -U postgres -c "SELECT * FROM loans"
     book     | reader 
--------------+--------
 Dom Casmurro | Bruno
(1 row)
```

**The row is there.** The container is new, its writable layer is new, and the data is the
volume's. Listing the volumes shows one, with a name a person can read, and no anonymous hash
beside it, because the image's declared volume path was filled by `pgdata` instead:

```
ana@vm:~$ docker volume ls
DRIVER    VOLUME NAME
local     pgdata
```

This is the shape every stateful container in this course takes from now on: the image is
replaced freely, the volume is kept, and **upgrading the database is starting a new container from
a new image against the same volume.** For PostgreSQL that only works within one major version; a
jump from 16 to 17 changes the format of the files in the volume, and needs the database's own
upgrade procedure, which no volume can do for you.

## Backing one up

A volume is not a backup: it lives on one disk of one machine. The usual way to copy one out is a
short-lived container that mounts the volume and a host directory, and archives one into the other:

```
ana@vm:~$ docker run --rm -v pgdata:/data:ro -v "$PWD":/backup alpine:3.22 tar -czf /backup/pgdata.tar.gz -C /data .
ana@vm:~$ ls -l pgdata.tar.gz
-rw-r--r-- 1 root root 4500389 Oct  6 13:42 pgdata.tar.gz
```

`pgdata:/data:ro` mounts the volume read-only, so the backup cannot change it; `"$PWD":/backup`
mounts Ana's current directory; `tar` inside writes the archive there. Two details deserve a look.
**The archive is owned by `root`**, because the container ran as root and wrote into Ana's
directory, which the next section explains and fixes. And **copying a running database's files is
not a consistent backup**: PostgreSQL may be halfway through writing them. For a database, stop the
container first, or use the database's own tool, `pg_dump`, through `docker exec`; the file copy is
right for volumes whose contents are not being written.
