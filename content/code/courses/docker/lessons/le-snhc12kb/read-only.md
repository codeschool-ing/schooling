---
title: A read-only filesystem
version: 1
---

**A container's filesystem is writable by default**, the writable layer of lesson 7. For a program
that writes nothing, that is only room for an intruder to drop a file, or for a bug to fill the disk.
`--read-only` mounts the whole image read-only:

```
ana@vm:~$ docker run --rm --read-only alpine:3.22 touch /etc/oops
touch: /etc/oops: Read-only file system
ana@vm:~$ docker run --rm --read-only --tmpfs /tmp alpine:3.22 sh -c "touch /tmp/scratch && ls /tmp && grep \" /tmp \" /proc/mounts"
scratch
tmpfs /tmp tmpfs rw,nosuid,nodev,noexec,relatime 0 0
ana@vm:~$ docker run -d --name web --read-only --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8080:8080 shelf:1.0.0
a1750792323c91ead7462b9e19b2cc7af44682f4fdaadcced7c968a362c49dbd
ana@vm:~$ curl -s localhost:8080/books | jq length
3
```

**`touch` was refused with `Read-only file system`.** Where a program needs scratch space, `--tmpfs`
mounts a small directory in memory: `/tmp` became writable, `nosuid`, `nodev` and `noexec`, so a file
written there cannot even be run. And `shelf`, which writes nothing, runs read-only with no
capabilities and no way to gain privileges, and answers as before.

## A program that writes

Postgres writes, and the first attempt shows where:

```
ana@vm:~$ docker run -d --name db --read-only -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17
53bd73aad98533cf87f90eb53b9967316b12a8e8d8820bfc8e2c8985cb05d0fb
ana@vm:~$ docker logs db 2>&1 | grep -i "read-only" | head -3
chmod: changing permissions of '/var/run/postgresql': Read-only file system
chmod: changing permissions of '/var/run/postgresql': Read-only file system
ana@vm:~$ docker run -d --name db --read-only --tmpfs /var/run/postgresql --tmpfs /tmp -e POSTGRES_PASSWORD=lab-only -v pgdata:/var/lib/postgresql/data postgres:17
accdcdbbc97905261014fff967d46bb7a9ee6be9d8b5cefe0ec15fbcbb9b744c
ana@vm:~$ docker exec db pg_isready -h 127.0.0.1
127.0.0.1:5432 - accepting connections
```

**The log names the directory**: `/var/run/postgresql`, where Postgres keeps its socket and lock file.
A `tmpfs` there and on `/tmp`, plus the volume it already had for its data, and it accepts
connections with the rest of the image read-only. That is the method for any image: start it
read-only, read what it fails to write, and give it exactly those places. **Data goes to a volume,
scratch to a `tmpfs`, and nothing else is writable.**

## What all of this looks like for `shelf`

In a Compose file, the flags of this lesson and the user from lesson 14 are four lines under the
service:

```yaml
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
```

**This block was not run as written**; each flag was, in the captures above. The service's user comes
from the image's `USER`.

## User namespaces

One more layer exists, and the lab does not turn it on. With **user namespace remapping**, set in the
daemon's `daemon.json` as `userns-remap`, UID 0 inside every container is an unprivileged UID on the
host, so even a process that got past every wall would arrive with no rights there. **Rootless mode**
goes further and runs the daemon itself as an ordinary user. Both cost some compatibility, with
volumes and some network features in particular, and both mean restarting or reinstalling the daemon,
which is why they appear here as text: Docker's documentation covers each, and lesson 28 meets Podman,
which runs rootless by default.
