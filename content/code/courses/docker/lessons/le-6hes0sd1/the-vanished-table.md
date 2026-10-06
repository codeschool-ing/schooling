---
title: The table that vanished
version: 1
---

**A database in a container loses its data the first time somebody removes the container and
starts another, unless the data was deliberately put somewhere else.** It is the most common data
loss in a first month with Docker, and with PostgreSQL it has a twist that is worth understanding,
because it also shows the way out.

Ana starts PostgreSQL, creates a table of loans and adds a row:

```
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only postgres:17
05d41ecdea4494230e0ff46bc8cda5bcd87a4ccab1d13ea5427258bc8767fc0d
ana@vm:~$ docker exec db psql -U postgres -c "CREATE TABLE loans (book text, reader text)" -c "INSERT INTO loans VALUES ('Dom Casmurro', 'Bruno')" -c "SELECT * FROM loans"
CREATE TABLE
INSERT 0 1
     book     | reader 
--------------+--------
 Dom Casmurro | Bruno
(1 row)
```

Then she does what people do when they want to change a setting: removes the container and runs
it again with the same command.

```
ana@vm:~$ docker rm -f db
db
ana@vm:~$ docker run -d --name db -e POSTGRES_PASSWORD=lab-only postgres:17
eea400da67ecfc95e1f4b20368be6658ef9865fced4ece88af64a21659293fb0
ana@vm:~$ docker exec db psql -U postgres -c "SELECT * FROM loans"
ERROR:  relation "loans" does not exist
LINE 1: SELECT * FROM loans
                      ^
```

**The table does not exist.** PostgreSQL started with an empty database, created afresh, as if the
first container had never run.

## Where the data actually went

That looks like the writable layer from the previous section disappearing, and it is not quite.
Ana lists the volumes on the machine:

```
ana@vm:~$ docker volume ls
DRIVER    VOLUME NAME
local     961db081cbe2c3b181ec267e08d4f001727faf79c3b616f91df158ae32d4f7ea
local     f61e9fe7c8d22b6c1cd6be17555250cb9b107eb622dafda810e26daf15975148
ana@vm:~$ docker inspect db --format "{{range .Mounts}}{{.Type}} {{.Name}} -> {{.Destination}}{{end}}"
volume f61e9fe7c8d22b6c1cd6be17555250cb9b107eb622dafda810e26daf15975148 -> /var/lib/postgresql/data
```

**Two volumes she never asked for**, each named by a long random hash, and the new `db` uses one
of them for `/var/lib/postgresql/data`, which is where PostgreSQL keeps its files. The reason is in
the image itself:

```
ana@vm:~$ docker image inspect postgres:17 --format "{{json .Config.Volumes}}"
{"/var/lib/postgresql/data":{}}
```

The `postgres` image declares that directory as a **volume**. Whenever a container starts from it
without being told what to put there, Docker creates an **anonymous volume**, a fresh one with a
hash for a name, and mounts it there. So the first container's table was never in its writable
layer: it was in the first anonymous volume. Removing the container left that volume behind, and
the second container got a new, empty one.

The data is still on the disk. Ana mounts the first volume, the one `db` is not using, into a new
container:

```
ana@vm:~$ docker rm -f db
db
ana@vm:~$ docker run -d --name rescued -e POSTGRES_PASSWORD=lab-only -v 961db081cbe2c3b181ec267e08d4f001727faf79c3b616f91df158ae32d4f7ea:/var/lib/postgresql/data postgres:17
d931c9253912810fe856a9430eac7a33cea3e71a8ff41f477f30910552469a6c
ana@vm:~$ docker exec rescued psql -U postgres -c "SELECT * FROM loans"
     book     | reader 
--------------+--------
 Dom Casmurro | Bruno
(1 row)
```

**The row is back.** Nothing was destroyed; it was detached, with nothing to say where it was.

## Why that is not good news

It would be easy to read this as "Docker keeps database data safe anyway". It does not, for three
reasons:

- **Nobody can tell which volume is which.** Two hashes, and only an `inspect` of the running
  container, or a guess, says which one holds yesterday's data. With ten restarts there are ten.
- **The usual clean-up deletes them.** `docker volume prune`, the command lesson 22 uses to free
  space, removes anonymous volumes no container is using, which is exactly what an orphaned database
  is. `docker run --rm` removes a container's anonymous volumes when it exits.
- **An image that declares no volume has none.** Most images do not, and for them the writable
  layer is all there is, and the previous section's rule applies directly.

**The fix is to name the volume.** `-v pgdata:/var/lib/postgresql/data` mounts a volume called
`pgdata`, created on first use, and every later container started with the same option gets the
same data. Lesson 8 is entirely about that option and its alternative.
