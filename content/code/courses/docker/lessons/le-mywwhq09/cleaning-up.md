---
title: Cleaning up
version: 1
---

**Docker deletes nothing by itself.** Every image pulled, every build step cached, every stopped
container and every volume stays until somebody removes it, and on a laptop or a CI runner that is
how a disk fills up in a month.

## Where the space went

```
ana@vm:~$ docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          6         3         1.967GB   1.905GB (96%)
Containers      3         2         12.29kB   4.096kB (33%)
Local Volumes   2         0         39.99MB   39.99MB (100%)
Build Cache     31        0         1.575GB   8.741MB
```

`docker system df` is the first command to run. **Images** are almost all of it here, 1.97 GB, and the
`RECLAIMABLE` column counts what no container uses. **Build cache**, lesson 12's, is the next largest.
**Local volumes** hold data, and that is the line to read twice.

## Containers

```
ana@vm:~$ docker container prune -f
Deleted Containers:
43190281ecae32609adfd2f08e67847352f242a657aafb7a58d004007b11a59c

Total reclaimed space: 4.096kB
ana@vm:~$ docker image ls --format "{{.Repository}}:{{.Tag}}" | sort
alpine:3.22
gcr.io/distroless/static-debian12:nonroot
golang:1.25
postgres:17
shelf:1.0.0
shelf:1.0.1
```

**`docker container prune` removes every stopped container**, here `once`, which had run `echo` and
exited. Running ones are never touched. A stopped container is cheap on disk, but it holds on to its
image, which then cannot be removed.

## Images

```
ana@vm:~$ docker rm -f web-old >/dev/null; docker image rm shelf:1.0.0
Untagged: shelf:1.0.0
Deleted: sha256:fe2860a0e74c3df182f423b734a85ac41c9686dc1dd730939a598061597ee387
ana@vm:~$ docker image prune -f
Total reclaimed space: 0B
```

`docker image rm` refused nothing here because `web-old` was removed first; with it still there, the
image would have been in use. **`docker image prune` alone removes only dangling images**, the
unnamed leftovers of rebuilt tags, of which there were none. `docker image prune -a` removes every
image no container uses, including `golang:1.25` and the other bases. It was not run here, because
the next build would download them again; on a CI runner that rebuilds from scratch anyway, it is the
common nightly job.

## Volumes: the one that loses data

```
ana@vm:~$ docker volume ls --format "{{.Name}}"
pgdata
scratch
ana@vm:~$ docker volume prune -f
Total reclaimed space: 0B
ana@vm:~$ docker volume prune -af
Deleted Volumes:
pgdata
scratch

Total reclaimed space: 39.99MB
```

**`docker volume prune` removed nothing, and `docker volume prune -a` removed both volumes.** Since
Docker Engine 23, plain `prune` removes only anonymous volumes, and `-a` extends it to named ones that
no container uses. `pgdata` held the database Ana had removed a minute earlier, kept in a named volume
precisely so that it would outlive its container; a stopped database is not using its volume either, so `-a`
takes it. **Never run `docker volume prune -a` on a machine whose data you have not checked**, and
never in a script that runs unattended.

## Build cache

```
ana@vm:~$ docker builder prune -f | tail -1
Total:	30.6MB
ana@vm:~$ docker builder prune -af | tail -1
Total:	1.545GB
ana@vm:~$ docker system df
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          5         1         1.946GB   1.917GB (98%)
Containers      1         1         4.096kB   0B (0%)
Local Volumes   0         0         0B        0B
Build Cache     0         0         0B        0B
```

Plain `docker builder prune` removed the cache no image refers to; **`-a` removed all of it, 1.5 GB**.
The next build of `shelf` will download modules and compile everything again, as lesson 12 measured.
That is the trade on every one of these commands: disk now against time on the next run.

| command | removes | risk |
| --- | --- | --- |
| `docker container prune` | stopped containers | their logs and writable layers |
| `docker image prune` | dangling images | none |
| `docker image prune -a` | images no container uses | download time |
| `docker builder prune -a` | all build cache | build time |
| `docker volume prune -a` | volumes no container uses | **data** |
| `docker system prune` | containers, networks, dangling images, cache | as above; `--volumes` adds volumes |
