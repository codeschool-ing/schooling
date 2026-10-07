---
title: Configuring the daemon, and when Engine is enough
version: 2
---

**`dockerd` reads its configuration from one JSON file, `/etc/docker/daemon.json`, when it
starts.** Every setting there is a default for the whole machine: where images come from, how
containers' logs are kept, which addresses networks are given. The file does not exist until
somebody writes it, and an engine with no file runs on built-in defaults.

The lab's file has one setting, and it is the reason the lab can pull images at all:

```
ana@vm:~$ cat /etc/docker/daemon.json
{
  "registry-mirrors": ["https://mirror.gcr.io"]
}
```

**`registry-mirrors`** makes the daemon fetch Docker Hub images through another server first. The
lab's anonymous pulls from Docker Hub were answered with `429 Too Many Requests`, Docker Hub's
rate limit, so the lab pulls through `mirror.gcr.io`, a public cache of Docker Hub that Google runs.
The image names, tags and digests stay Docker Hub's; only the server that sends the bytes changes.
Companies use the same setting to point every machine at their own cache. Your machine starts with
no file and needs none; if the `429` from lesson 5's last section reaches you, those three lines and
a restart are the way round it.

A change to the file takes effect when the daemon restarts, `sudo systemctl restart docker` on a
systemd machine, and a file with a JSON error stops the daemon from starting at all. That is the
most common way to break a working installation, so check the file with `jq . /etc/docker/daemon.json`
before restarting.

## What the daemon reports about itself

```
ana@vm:~$ docker info | grep -E "^ (Server Version|Storage Driver|Logging Driver|Cgroup Driver|Cgroup Version|Docker Root Dir):"
WARNING: Support for cgroup v1 is deprecated and planned to be removed by no later than May 2029 (https://github.com/moby/moby/issues/51111)
 Server Version: 29.8.2
 Storage Driver: overlayfs
 Logging Driver: json-file
 Cgroup Driver: cgroupfs
 Cgroup Version: 1
 Docker Root Dir: /var/lib/docker
ana@vm:~$ docker info --format "{{.RegistryConfig.Mirrors}}"
[https://mirror.gcr.io/]
```

Each line is a decision somebody can change, and each one has a lesson:

- **`Storage Driver: overlayfs`** is how image layers and containers' writable layers are stored,
  the stacking lesson 4 took apart.
- **`Logging Driver: json-file`** means each container's output is kept as a file of JSON lines on
  this machine, which is what `docker logs` reads. By default those files grow without a limit,
  and lesson 18 sets one.
- **`Cgroup Driver` and `Cgroup Version`** are lesson 4's limits. The `WARNING` above them is the
  daemon saying that support for cgroup v1, which the lab machine runs, is deprecated; a current
  distribution runs v2 and prints no warning.
- **`Docker Root Dir: /var/lib/docker`** is where all of it lives on disk.

```
ana@vm:~$ sudo du -sh /var/lib/docker
24M	/var/lib/docker
```

24M, because the lab has only `alpine:3.22` pulled. On a machine that has built images for a few
months that directory is often tens of gigabytes, and lesson 22 shows how to see what is taking the
space and reclaim it safely. Never delete files inside it by hand: the daemon's records and the
files would disagree, and it would no longer start reliably.

## When Docker Engine is all you need

**Docker Engine on its own is everything a Linux machine needs to build and run containers.**
Docker Desktop adds a VM, which Linux does not need, and a graphical window, which a server never
uses.

| the machine | what to install |
| --- | --- |
| a Linux server that runs containers | Docker Engine, or only containerd if an orchestrator manages it (lesson 28) |
| a CI runner that builds images | Docker Engine, and BuildKit comes with it |
| a Linux laptop | Docker Engine, plus the group or rootless mode from the previous section |
| a Windows or macOS laptop | Docker Desktop, or an alternative that also runs a Linux VM (lesson 28) |

The rest of this course runs on exactly that: one Linux machine, one Docker Engine, nothing else.
