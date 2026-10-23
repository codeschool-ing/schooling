---
title: A read-only filesystem, and the two places linkbox writes
version: 1
---

`--read-only` mounts the image's whole filesystem read-only, so nothing in the container can change
a file that came with the image, whoever the process is. The method `docker` lesson 21 used on
Postgres works on any image: **start it read-only, read what it fails to write, and give it exactly
those places.** linkbox fails twice, and each failure names its place.

### First failure: gunicorn will not start

```
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
4a79c78038ef2424d25a8f3defd7c0bf490c63315479c033d8faa1cc6cf8e7fd
ana@vm:~/linkbox$ docker ps -a --filter name=linkbox --format "{{.Status}}"
Exited (255) 2 seconds ago
ana@vm:~/linkbox$ docker logs linkbox 2>&1 | tail -n 3
                            "No usable temporary directory found in %s" %
                            dirlist)
FileNotFoundError: [Errno 2] No usable temporary directory found in ['/tmp', '/var/tmp', '/usr/tmp', '/app']
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

**The container had already exited when asked**, and the last line of the log names the problem:
`No usable temporary directory found in ['/tmp', '/var/tmp', '/usr/tmp', '/app']`. That is Python's
`tempfile` module, which tried the usual places and the working directory, and found nothing it
could write. gunicorn needs one before it serves a single request: each worker keeps a small
temporary file that it touches as a heartbeat, so the master can tell a stuck worker from a busy
one. linkbox's own code never asked for a temporary file, which is why no test ever noticed.

A temporary directory is scratch space, gone when the container stops, and that is exactly what a
`tmpfs` is: a filesystem in memory, mounted at one path.

### Second failure: the first write

```
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only --tmpfs /tmp -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
5751d0672951c4c6a91ca93ec239c77d0dd13178d20b71da0d8c2c38753dbfa7
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links
500
ana@vm:~/linkbox$ docker logs linkbox 2>&1 | grep Error
sqlite3.OperationalError: unable to open database file
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
```

gunicorn starts, and **the first request that touches the database answers 500**. The log says
`unable to open database file`: SQLite could not create `/data/linkbox.db`, because `/data` is part
of the image and the image is read-only now. This failure is worse than the first, because the
container is up and healthy-looking until somebody uses it; a staging run that only checked the
container had started would have passed it.

Where linkbox keeps its data is a decision about the data, not about the filesystem. In staging the
data is thrown away after the scan, so a `tmpfs` is right. In production it has to outlive the
container, and it belongs on a volume, which lesson 10 gives it as a Kubernetes volume. Either way,
it is a mount of its own, and the rest stays read-only:

```
ana@vm:~/linkbox$ docker run -d --name linkbox --read-only --tmpfs /tmp --tmpfs /data:uid=65532,gid=65532 -p 127.0.0.1:8000:8000 -e LINKBOX_TOKEN=local-only linkbox:dev
f0ef124b2d1d1c55e03b3ee5ec6d8440843f33754842581d5a0ff5e7ddd9445d
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: local-only" -d url=https://example.org/handbook http://127.0.0.1:8000/links
{"code":"rMPeDg"}
ana@vm:~/linkbox$ docker exec linkbox python3 -c "print(open('/proc/mounts').read(), end='')" | grep -E ' (/|/tmp|/data) '
overlay / overlay ro,relatime,lowerdir=1080/fs:910/fs:909/fs:908/fs:907/fs:253/fs:252/fs:251/fs:250/fs:249/fs:248/fs:247/fs:246/fs:245/fs:244/fs:243/fs:242/fs:241/fs:240/fs:239/fs:238/fs:237/fs:236/fs:235/fs:234/fs:233/fs:232/fs:231/fs:230/fs:229/fs:228/fs:227/fs:226/fs:225/fs:224/fs:223/fs:222/fs:221/fs:220/fs:219/fs:218/fs:217/fs:216/fs:215/fs:214/fs:213/fs:212/fs:211/fs:210/fs:209/fs:208/fs:207/fs:206/fs,upperdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/1081/fs,workdir=/var/lib/docker/containerd/daemon/io.containerd.snapshotter.v1.overlayfs/snapshots/1081/work 0 0
tmpfs /data tmpfs rw,nosuid,nodev,noexec,relatime,mode=755,uid=65532,gid=65532 0 0
tmpfs /tmp tmpfs rw,nosuid,nodev,noexec,relatime 0 0
ana@vm:~/linkbox$ docker rm -f linkbox
linkbox
ana@vm:~/linkbox$ docker run --rm --read-only --user 0 --entrypoint python3 linkbox:dev -c "open('/app/app.py', 'a')"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
    open('/app/app.py', 'a')
    ~~~~^^^^^^^^^^^^^^^^^^^^
OSError: [Errno 30] Read-only file system: '/app/app.py'
```

**201 and a code: the service works with exactly two writable places.** The mount table shows the
three that matter. The root is `overlay` mounted `ro`. `/tmp` and `/data` are `tmpfs`, and Docker
mounts them `nosuid`, `nodev` and `noexec`: a file written there cannot be run as a program,
cannot carry a setuid bit and cannot be a device. `uid=65532,gid=65532` makes `/data` belong to the
user the application runs as, the way lesson 8's image arranged it. A `tmpfs` with no owner is
writable by everybody in the container, which works and says less about who the directory is for.

The last command is the point of the whole exercise. **The same `--user 0` that rewrote `app.py` in
the last section now gets `Read-only file system`.** The protection no longer depends on who the
process is.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l09-mounts\" aria-label=\"linkbox's filesystem when it runs read-only. The root, from the image, is an overlay mounted ro and holds /app and /packages. Two tmpfs mounts are writable, nosuid, nodev and noexec: /tmp, where each gunicorn worker keeps its heartbeat file, and /data, owned by 65532, where SQLite keeps linkbox.db. Both live in memory and disappear when the container stops.\"><defs></defs><rect x=\"15\" y=\"15\" width=\"690\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/</text><text x=\"46\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the image: overlay, ro</text><rect x=\"35\" y=\"60\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/app</text><text x=\"110.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the code</text><rect x=\"35\" y=\"130\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">/packages</text><text x=\"110.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the packages</text><rect x=\"260\" y=\"60\" width=\"420\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">/tmp  tmpfs  rw,noexec</text><text x=\"470.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gunicorn's heartbeat files</text><rect x=\"260\" y=\"130\" width=\"420\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">/data  tmpfs  rw,noexec</text><text x=\"470.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">SQLite: linkbox.db, owner 65532</text><text x=\"470\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">in memory, gone when the container stops</text></svg>", "caption": "One read-only filesystem and two small writable ones, each there because the application failed without it."}
```

### What `noexec` does not stop

`noexec` stops the kernel from executing a file in `/tmp` as a program. It does not stop `python3`
from reading a `.py` file there and running its contents, because the interpreter is the program
and the file is only its input. A read-only root and a `noexec` scratch directory take away the
easy ways to plant a tool and keep it; they do not make code execution impossible in a container
that has an interpreter in it. That is why this lesson does not stop at the filesystem.

### Finding the places for any image

linkbox needed two places and found both in two tries. A larger application can need more, and the
order of work is the same: run it read-only in staging, exercise it (start it, send a request to
every route that writes, run a job if it has one), read the errors, add a mount for each, and
**write the list down in the place that starts the container**, so it is reviewed like code. For
linkbox that place is the staging script of the last section, and from lesson 10 the manifest.
