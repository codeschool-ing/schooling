---
title: Looking inside a distroless container
version: 1
---

**The first thing most people try with a misbehaving container is a shell inside it.** On `shelf`
there is none, on purpose, since lesson 14:

```
ana@vm:~$ docker exec web sh
OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

That is not the dead end it looks like. **Almost everything a shell would be used for can be done
from outside**, and doing it from outside leaves the image as small as it was.

## Five ways in that need no shell

```
ana@vm:~$ docker top web -o pid,user,args
PID                 USER                COMMAND
11464               65532               /shelf
ana@vm:~$ docker diff web
ana@vm:~$ docker cp web:/shelf ./shelf-from-container && ls -l shelf-from-container
-rwxr-xr-x 1 ana ana 14735361 Oct  6 17:41 shelf-from-container
ana@vm:~$ docker run --rm --network container:web alpine:3.22 wget -qO- localhost:8080/health
ok
ana@vm:~$ docker run --rm --pid container:web alpine:3.22 ps -o pid,user,args
PID   USER     COMMAND
    1 65532    /shelf
   19 root     ps -o pid,user,args
```

Each answers its own question:

- **`docker top`** lists the container's processes, from the host: `/shelf`, as UID 65532.
- **`docker diff`** lists what the container changed in its writable layer, added (`A`), changed
  (`C`) or deleted (`D`). Nothing, here, which is what a program that writes nothing should show and
  what a read-only container (lesson 21) guarantees.
- **`docker cp`** copies a file out of a container, or into one, running or stopped. Ana takes the
  binary itself, to compare it with what she built.
- **A second container in the same network namespace**, `--network container:web`, sees the first
  one's `localhost`. An Alpine container brings `wget` and asks `shelf` for `/health` exactly as
  `shelf`'s neighbours would.
- **A second container in the same process namespace**, `--pid container:web`, sees the first one's
  processes: `/shelf` as process 1, and the borrowed `ps` beside it.

The last two are the useful trick: **bring the tools in a container of their own, and join it to the
namespaces of the one you are looking at.** Lesson 4 showed that a container is a set of namespaces;
these flags share one of them on purpose. The debugging container leaves when it is done, and the image
in production never had to carry `wget` or `ps`.

`docker debug`, a command of Docker Desktop, packages the same idea with a toolbox
already in it. It was not available in the lab; the two flags above are what it builds on, and they
are in every Docker Engine.
