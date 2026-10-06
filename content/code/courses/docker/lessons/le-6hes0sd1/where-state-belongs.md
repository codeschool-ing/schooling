---
title: Where each kind of state belongs
version: 1
---

**Treat every container as something you will delete, and put each kind of state somewhere that
outlives it.** That rule is what makes containers useful: a container that holds nothing of its own
can be replaced by a new one from a new image, on any machine, at any time, and nobody has to
remember what was inside the old one.

"State" is not one thing. Each kind has its own right place:

| what | where it belongs | lesson |
| --- | --- | --- |
| data the application owns: a database, uploaded files | a named volume | 8 |
| files you edit on the host while developing | a bind mount | 8 |
| configuration that differs between laptop and production | environment variables or a mounted file, at `docker run` | 17 and 18 |
| secrets: passwords, keys | a secret file, never the image | 18 |
| logs | the container's standard output, collected by the engine | 18 |
| the program and its dependencies | the image, built from a Dockerfile | 11 |
| caches and temporary files | the writable layer, or `tmpfs`; losing them is fine | 8 |

The last row is the only kind of state the writable layer is good for: things that are allowed to
disappear.

## The tempting shortcut: `docker commit`

There is a command that turns a container's writable layer into an image, and it looks like the
answer to this whole lesson. Ana writes another note into `notes` and commits it:

```
ana@vm:~$ docker exec notes sh -c "echo second note > /notes.txt"
ana@vm:~$ docker commit notes notes:snapshot
sha256:1f0cab8ec0bf8809da8da6dbbb0be953b90f9e904a4ab9bae4fc4dbcc6f0c9a0
ana@vm:~$ docker history notes:snapshot
IMAGE          CREATED                  CREATED BY                                      SIZE      COMMENT
1f0cab8ec0bf   Less than a second ago   sleep 3600                                      8.19kB    
5291449c3df7   2 weeks ago              CMD ["/bin/sh"]                                 0B        buildkit.dockerfile.v0
<missing>      2 weeks ago              ADD alpine-minirootfs-3.22.6-x86_64.tar.gz /…   8.97MB    buildkit.dockerfile.v0
```

It works: `notes:snapshot` is an image, and a container started from it has the file. **And it is
the wrong habit, for two reasons visible in that history.** The new layer is described as `sleep
3600`, the command the container happened to be running, so the image records nothing about how
`/notes.txt` got there. Nobody can rebuild it, review it, or apply the same change to the next
version of Alpine. And it captures everything in the layer, including whatever else a process
wrote that nobody noticed.

The way to make an image with a file in it is to write down the steps in a Dockerfile, which
lesson 11 starts. `docker commit` has one honest use: keeping a broken container's exact state to
investigate later, as evidence rather than as a product.

## A checklist before you rely on a container

Before removing any container that has been running for a while, the answers to three questions
decide whether anything is lost:

1. **Does `docker diff` list anything that matters?** If so, it is in the writable layer and goes
   with the container.
2. **Do its mounts include an anonymous volume?** `docker inspect` lists them; a hash name means
   nobody chose it, and it will be orphaned.
3. **Would starting a new container from the same image, with the same options, give the same
   result?** If not, something about this container lives only in it, and that is the thing to
   move.
