---
title: Four checks after installing
version: 1
---

**Four commands tell you whether an installation works, and they ask the same questions on Docker
Desktop and on Docker Engine.** The transcripts below are from the course's lab, a Linux server
running Engine. Where Desktop answers differently, the text says how, and shows no output that was
not recorded here.

## 1. Two halves answer

```
ana@vm:~$ docker version
Client: Docker Engine - Community
 Version:           29.8.2
 API version:       1.56
 Go version:        go1.26.8
 Git commit:        7fc2dff
 Built:             Wed Sep 30 19:32:28 2026
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          29.8.2
  API version:      1.56 (minimum version 1.40)
  Go version:       go1.26.8
  Git commit:       8af9fe3
  Built:            Wed Sep 30 19:32:28 2026
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          v2.3.6
  GitCommit:        ee2735368117d2eb259779949d5e75cdafec9761
 runc:
  Version:          1.5.1
  GitCommit:        v1.5.1-0-g8f2685a4
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

**`docker version` answers in two blocks, and both have to be there.** `Client` is the `docker`
command itself; `Server` is the engine it talked to, with the versions of containerd and runc
under it, which lesson 6 explains. If only the client block appears, followed by an error, the
command is installed and the engine is not reachable; check 4 below shows that error.

On Docker Desktop the server block names Docker Desktop, and the two `OS/Arch` lines disagree: the
client is `windows/amd64` or `darwin/arm64`, because it runs on your system, while the server is
`linux/…`, because it runs in the VM. That disagreement is the picture from the previous section,
printed.

## 2. A container runs

```
ana@vm:~$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
4f55086f7dd0: Pulling fs layer
4f55086f7dd0: Download complete
4f55086f7dd0: Pull complete
d5e71e642bf5: Download complete
Digest: sha256:5e23090353324d887c48ad5e5c56d294eab81588df9605b07d1afe895f9cc8f8
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

**`hello-world` is the smallest end-to-end test there is.** Everything down to `Status:` is the
pull: the image was not on the machine, so the engine fetched it, a single layer, and named it by
its digest.
Then the container ran a program that prints the text below, and the text describes the trip it
just took: client to daemon, daemon to Docker Hub, image to container, output back to the client.
If this works, the engine, the network to the registry and the runtime all work.

## 3. Which engine you are talking to

```
ana@vm:~$ docker context ls
NAME        DESCRIPTION                               DOCKER ENDPOINT               ERROR
default *   Current DOCKER_HOST based configuration   unix:///var/run/docker.sock   
```

A **context** is a named engine the `docker` command can talk to; the `*` marks the current one.
On the lab there is only `default`, the engine on this machine's own socket. Docker Desktop adds one
called `desktop-linux` and makes it current, which is why the same command reaches the VM. When a
machine has more than one engine, `docker context use <name>` switches between them, and
`docker context ls` is the first thing to run when containers seem to have disappeared: usually
they are on the other engine.

## 4. What the engine has

```
ana@vm:~$ docker info --format "{{.OperatingSystem}} | {{.OSType}}/{{.Architecture}} | {{.NCPU}} CPUs | {{.MemTotal}} bytes"
Ubuntu 24.04.5 LTS | linux/x86_64 | 4 CPUs | 16876511232 bytes
```

`docker info` can be asked for single fields, like this. On the lab it reports the server itself:
Ubuntu, `x86_64`, 4 processors and about 16 GB. **On Docker Desktop the same fields describe the
VM**, not your laptop: a different operating system name, and the processors and memory the
settings screen gave the VM. That is the number containers are limited by, so this command is the
quick way to check the setting.

## And the error you will see first

When the engine is not running, or the `docker` command is pointed somewhere nothing listens, the
client says so. The lab produces it by pointing `DOCKER_HOST` at a socket that does not exist:

```
ana@vm:~$ DOCKER_HOST=unix:///run/not-running.sock docker ps
failed to connect to the docker API at unix:///run/not-running.sock; check if the path is correct and if the daemon is running: dial unix /run/not-running.sock: connect: no such file or directory
```

**"failed to connect to the docker API" means the client is fine and the engine is not there.** On
Docker Desktop that nearly always means the application is not running yet, or is still starting;
open it and wait. On Linux it means the `docker` service is stopped, and lesson 6 shows how to start
it. The path in the message tells you which socket the client tried, which settles the
wrong-context case from check 3.
