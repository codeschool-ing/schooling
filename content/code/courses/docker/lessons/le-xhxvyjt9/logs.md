---
title: Where the logs go
version: 1
---

**A container's standard output and standard error are its log, and the daemon writes them to a file
on the host.** `docker logs` reads that file back. Which file, and whether it ever stops growing, is
decided by the **logging driver**:

```
ana@vm:~/shelf$ docker info --format "{{.LoggingDriver}}"
json-file
ana@vm:~/shelf$ docker run -d --name chatty alpine:3.22 yes "one more line of log"
919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963
ana@vm:~/shelf$ docker logs --tail 2 chatty
one more line of log
one more line of log
ana@vm:~/shelf$ docker inspect chatty --format "{{.LogPath}}"
/var/lib/docker/containers/919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963/919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963-json.log
ana@vm:~/shelf$ sudo du -h "$(docker inspect chatty --format "{{.LogPath}}")"
183M	/var/lib/docker/containers/919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963/919157e553fd7bccdce07a6c57bb3e886f4e5a92d2f657ba2d204f01f4e28963-json.log
```

`json-file` is the default: one JSON object per line, in a file under `/var/lib/docker/containers/`.
**And by default it has no size limit.** The container above is `yes`, a program that prints the same
line as fast as it can, standing in for a service stuck logging an error in a loop. In the three
seconds before Ana looked, it wrote **183 MB**. At that rate a day fills any disk, and with the disk
goes every other container on the machine, and the daemon itself.

## Rotation, per container

Two log options cap it: `max-size` for one file, and `max-file` for how many are kept:

```
ana@vm:~/shelf$ docker run -d --name chatty --log-opt max-size=1m --log-opt max-file=3 alpine:3.22 yes "one more line of log"
5c4dcd7687352387b3bff6cfeabe334c91ba3882b4b638c0110f436586851363
ana@vm:~/shelf$ sudo ls -l "$(dirname "$(docker inspect chatty --format "{{.LogPath}}")")" | grep json.log
-rw-r----- 1 root root  993809 Oct  6 15:05 5c4dcd7687352387b3bff6cfeabe334c91ba3882b4b638c0110f436586851363-json.log
-rw-r----- 1 root root 1000082 Oct  6 15:05 5c4dcd7687352387b3bff6cfeabe334c91ba3882b4b638c0110f436586851363-json.log.1
-rw-r----- 1 root root 1000059 Oct  6 15:05 5c4dcd7687352387b3bff6cfeabe334c91ba3882b4b638c0110f436586851363-json.log.2
```

**Three files of about 1 MB, and nothing more, however long it runs.** The oldest lines are dropped,
which is the trade: rotation protects the machine, and anything older than the files hold is gone
unless something shipped it elsewhere first.

## Rotation, for every container

Writing `--log-opt` on every `docker run` is a promise somebody will forget. The daemon takes a
default in `/etc/docker/daemon.json`, the same file lesson 6 used for the registry mirror:

```json
{
  "registry-mirrors": ["https://mirror.gcr.io"],
  "log-driver": "local",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

**This file was written in the lab and not installed**, because applying it means restarting the
daemon, and the lab's daemon stays as lesson 6 left it. Two things are true of it by Docker's
documentation: the change takes effect after a restart of the daemon, and **only for containers
created after it**; existing ones keep the options they were created with. The `local` driver it
selects stores logs in a compact format and rotates them by default, and `docker logs` reads it the
same way.

## Somewhere other than the machine

The file on the host is fine for one machine and for `docker logs`. A fleet sends its logs to one
place where they can be searched after the container is gone: other drivers, such as `syslog`,
`journald`, `gcplogs` and `awslogs`, write straight to such a place, or an agent on each host reads
the files and forwards them. The program does not change either way, **which is why a containerised
program logs to standard output and never to a file of its own**: where the lines go is the
platform's decision, made outside the image.
