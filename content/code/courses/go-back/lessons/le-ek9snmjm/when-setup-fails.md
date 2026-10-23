---
title: When the setup fails
version: 1
---

The first command most people type after installing is refused:

```
ana@vm:~$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

**The client works and cannot reach the server.** `docker` is a client that talks to the daemon over the
socket `/var/run/docker.sock`, and only root and the group `docker` may open it:

```
ana@vm:~$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
ana@vm:~$ sudo usermod -aG docker $USER
ana@vm:~$ id -nG; docker ps
ana docker
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Add yourself to the group, then log out and in again, because a running session keeps the groups it
started with; `id -nG` lists the ones the shell has now. **Know what the group grants first.** The daemon
runs as root and does whatever a member asks, including starting a container with any directory of the
machine mounted inside it, so membership is root on that machine by another route. The `docker` course's
lesson 6 shows it reading a file only root may read. On your own machine that is fine; on a shared server,
the group gets the same care as `sudo`, and rootless Docker or Podman is the answer when that trust cannot
be given.

When the daemon is not running at all, the message names the socket and asks whether it is:

```
ana@vm:~$ DOCKER_HOST=unix:///run/nobody-here.sock docker ps
failed to connect to the docker API at unix:///run/nobody-here.sock; check if the path is correct and if the daemon is running: dial unix /run/nobody-here.sock: connect: no such file or directory
```

That one was made by pointing `docker` at a socket nobody listens on; a stopped daemon looks the same with
the real path. On a systemd machine, `sudo systemctl start docker` starts it and
`sudo journalctl -u docker` says why it did not.

Two more failures come from outside your machine:

- **A registry refusing the pull.** Docker Hub limits how many images an anonymous client may pull in a
  period, and past the limit it answers `429 Too Many Requests`. Signing in with `docker login` raises
  the limit. The image this lesson builds on comes from Google's registry, `gcr.io`, which is a different
  service with its own limits.
- **No space left.** Images and build caches accumulate. `docker system df` shows what they take, and
  `docker image prune` and `docker builder prune` give it back.
