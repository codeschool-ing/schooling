---
title: Docker Engine, so a test can have a database
version: 1
---

The tests so far need nothing but a JDK. The next ones need a real PostgreSQL 16, and not the one
lesson 9 installed: that database holds whatever you last did to it by hand, and a test that passes
because of a row you inserted last Tuesday proves nothing. **Testcontainers starts a fresh database
in a container for each test run and throws it away afterwards**, and for that the machine needs a
container engine. This course uses **Docker Engine**, the open-source daemon from Docker, and the
`docker` command that talks to it.

A **container** is a process the engine starts with a file system of its own, unpacked from an
**image**, and walled off from the rest of the machine: it sees its own files, its own processes and
its own network address. An image of PostgreSQL 16 holds the server and everything it needs, so a
container made from it is a database server that exists for as long as the test run does. Lesson 1
used the same thing once as a clean machine made in one line, to show what a fresh Ubuntu says when
Java is missing.

This is the minimum the course needs from Docker. The `docker` course is where containers are taught
properly, and its lesson 5 installs the engine in exactly the way shown here, so a student who comes
to it after this course finds it already done.

## Three ways to have an engine

| | what it is | what it costs |
| --- | --- | --- |
| **in the same virtual machine** (recommended) | Docker Engine from Docker's own package repository, inside the Ubuntu 24.04 VM this course has used since lesson 1 | a few hundred megabytes of disk for the engine, plus the images, which the last section of this lesson measures; and 4 GB of memory for the VM, as lesson 1 sized it, because the tests run a JVM and a database side by side |
| Docker Desktop on your computer | Docker's application for Windows and macOS, which runs a Linux VM of its own | that VM's memory and disk, set in its settings; a paid licence at a large company; and `docker` then runs on your computer, so the tests would have to run there too, outside the VM |
| a remote engine | `DOCKER_HOST` pointing at a Docker Engine on another machine | nothing local; a machine you must keep running, and the database the tests start is on that machine, reached over the network |

**Pick the first one.** The tests in this lesson run inside the VM, with Maven, and Testcontainers
looks for the engine on the same machine. Desktop works when the whole project lives on your
computer rather than in the VM; a remote engine works and makes every test run wait on a network.
Neither is used again in this course.

## Installing it

Inside the VM, the commands are Docker's own installation instructions for Ubuntu. They add Docker's
signing key and package repository to `apt`, then install the engine and its command-line client.
Docker's documentation is the place to check them first, because the details change:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

One more line lets your user talk to the engine without `sudo`:

```sh
sudo usermod -aG docker $USER
```

**A new group takes effect at the next login.** Log out of the VM and back in, or close the
terminal and open another. Nothing above was run on the machine this course was recorded on, which
had Docker's packages installed before the course began; what follows is how the result is checked,
and it was.

```
ana@vm:~/bookshop$ id -nG
ana docker
ana@vm:~/bookshop$ ls -l /var/run/docker.sock
srw-rw---- 1 root docker 0 Oct 22 19:09 /var/run/docker.sock
```

`docker` in the list of groups means the new login took. The socket is the engine's door: owned by
`root`, readable and writable by the group `docker`, and by nobody else. Being in that group is
therefore the same as being able to start any container, including one that mounts the whole disk,
which is why `docker` lesson 6 calls membership what it is, root on that machine. In a VM that exists
to be thrown away, that is a fair trade.

Two checks decide whether the engine works:

```
ana@vm:~/bookshop$ docker version
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
command; `Server` is the engine it reached through the socket, with the versions of the pieces under
it. A client block followed by an error means the command is installed and the engine is not
reachable, and the next section is about exactly that.

```
ana@vm:~/bookshop$ docker run --rm hello-world

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

**`hello-world` is the smallest test that goes all the way through**: the engine did not have the
image, fetched it from Docker Hub, made a container from it and ran it, and the container's program
printed the text, which describes the trip it just took. `--rm` removed the container when it ended.
Testcontainers does the same four things for every database it starts, through the same socket.
