---
title: Root by default
version: 1
---

**Unless an image says otherwise, its container's process runs as root, user 0.** Lesson 4 showed
that Docker gives containers no user namespace by default, so that root is the host's root, held
back only by the other walls. Every one of those walls is a line of defence; a process that is not
root to begin with is one more, and it is the cheapest one there is.

Ana's image from lesson 13 sets no user, and the distroless base it is built on names root
explicitly:

```
ana@vm:~/shelf$ docker build -q -t shelf:root .
sha256:7eab1a08a6c6e2a934a60fc48a9fd1e879587e0a813565a8ac95fe8902b75e3e
ana@vm:~/shelf$ docker image inspect shelf:root --format "User: [{{.Config.User}}]"
User: [0]
ana@vm:~/shelf$ docker run -d --name as-root shelf:root
4d3b4bf986ecae5f7071e19f5b89e732bbae5559df1e9a6fc05acf49985d90e0
ana@vm:~/shelf$ docker top as-root -o pid,uid,args
PID                 UID                 COMMAND
3105                0                   /shelf
```

`User: [0]`, and `docker top` agrees: `/shelf` runs as UID 0. Nothing about `shelf` needs that. It
reads no protected file, listens on a high port and writes nothing to disk.

## What root inside costs

Root inside a container is not automatically root on the host, because namespaces, cgroups and the
restrictions lesson 21 covers still apply. **What it changes is how much a single mistake is worth.**
Three examples, each a real class of incident:

- **A bind mount gives root's power over the host directory.** Lesson 8's container wrote a
  root-owned file into Ana's home; a container mounting `/etc` as root could rewrite the host's
  configuration.
- **A flaw in the kernel or the runtime that lets a process past the walls lands it on the host as
  the user it was.** As root, that is the whole machine. As UID 65532, a user with no rights on the
  host, it is very little.
- **A bug in the program becomes root's bug.** If `shelf` had a hole that let a request write a file
  of the attacker's choosing, root could write it anywhere in the container's filesystem, including
  over the program itself.

None of these needs root to be useful to an attacker, and every one of them is worse with it. That
is the whole argument for the next section, and it is why Kubernetes, in lesson 25 of the `kubernetes`
course, can refuse to start a container that would run as root.
