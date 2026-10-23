---
title: No capabilities, and no way to gain new privileges
version: 1
---

The filesystem is now read-only; the process still has fourteen capabilities within reach and a
door open to gaining more. Two flags close both. **`--cap-drop ALL` empties the bounding set, and
`--security-opt no-new-privileges` stops any program the container executes from running with more
privilege than the process that started it.** linkbox needs neither capabilities nor setuid
programs, so it should run without both, and the only way to know that it does is to run it:

```
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
8f3d9ec3375175f70dd0f7c864b134d3211470b172a01886935d5c29114224d1
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links
{"code":"F1dZMQ"}
ana@vm:~/linkbox$ docker exec linkbox python3 -c "$status"
Uid:	65532	65532	65532	65532
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	0000000000000000
CapAmb:	0000000000000000
NoNewPrivs:	1
Seccomp:	2
Seccomp_filters:	1
```

**The service answers, and the status has changed in two lines.** `CapBnd` is zero: no process in
this container can ever hold a capability, not even one running as root. `NoNewPrivs` is 1, and it
cannot be switched back off from inside: the kernel lets a process set it and never clear it, and
every process started from it inherits it.

### Root without capabilities

What a capability is worth shows when root loses it. Changing the owner of a file is an operation
the kernel allows a process holding `CAP_CHOWN`, which root has by default:

```
ana@vm:~/linkbox$ docker run --rm --user 0 --entrypoint python3 linkbox:dev -c "import os; os.chown('/data', 0, 0); print('chowned')"
chowned
ana@vm:~/linkbox$ docker run --rm --user 0 --cap-drop ALL --entrypoint python3 linkbox:dev -c "import os; os.chown('/data', 0, 0); print('chowned')"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    import os; os.chown('/data', 0, 0); print('chowned')
               ~~~~~~~~^^^^^^^^^^^^^^^
PermissionError: [Errno 1] Operation not permitted: '/data'
```

**The same command, the same user 0, and the kernel refuses it once the capability is gone.** That
is the meaning of the bounding set: root in a container with `--cap-drop ALL` still owns the files
root owns, and can read and write them where the filesystem allows, but it cannot do any of the
things that need a capability, from changing an owner to binding a port below 1024 or opening a raw
socket. Combined with the read-only root, a process started with `--user 0` by mistake can do
little that 65532 could not.

The alternative some teams use is to drop everything and add back one capability, such as
`--cap-add NET_BIND_SERVICE` for a server that must listen on port 80. linkbox listens on 8000 and
needs no exception. **Each `--cap-add` is a line that somebody should be able to justify on
review**, which is easier when the default is none.

### What `no-new-privileges` protects against

A setuid program runs as its owner rather than as the user who started it; `passwd` and `sudo` are
the classic examples, owned by root so that an ordinary user can do one privileged thing through
them. A file capability does the same for a single capability. Either one, present in an image, is
a path from user 65532 to more privilege. This image has none:

```
ana@vm:~/linkbox$ docker exec linkbox python3 -c "import os, stat; print([os.path.join(d, f) for d, _, fs in os.walk('/usr') for f in fs if os.path.isfile(os.path.join(d, f)) and os.stat(os.path.join(d, f)).st_mode & stat.S_ISUID])"
[]
```

An empty list for everything under `/usr`, which is what a distroless image looks like. So why set
the flag? **Because it protects the image that comes next, not this one.** A later base image, a
package added in a hurry, a debugging tool copied in: any of them can bring a setuid file, and
nobody reviews an image's file modes. The flag costs nothing for a program that never needed new
privileges, and it removes the class of mistake rather than the instance.

### Four controls, and what each one assumes

| control | what it removes | what it assumes |
|---|---|---|
| `USER 65532` in the image | root by default | nobody passes `--user 0` |
| `--cap-drop ALL` | every capability, for every user | nothing |
| `--security-opt no-new-privileges` | gaining privilege by executing a file | nothing |
| `--read-only` and two `tmpfs` | changing the image's files | nothing |

The first row is the one most images stop at, and it is the only one with an assumption in its
last column. The other three hold whatever the process is and however it was started, which is
the property a control in the pipeline needs.
