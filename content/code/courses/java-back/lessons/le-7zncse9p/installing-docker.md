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

This is the minimum the course needs from Docker. The `docker` course is where containers are taught
properly, and its lesson 5 installs the engine in exactly the way shown here, so a student who comes
to it after this course finds it already done.

## Three ways to have an engine

| | what it is | what it costs |
| --- | --- | --- |
| **in the same virtual machine** (recommended) | Docker Engine from Docker's own package repository, inside the Ubuntu 24.04 VM this course has used since lesson 1 | about 500 MB of disk for the engine, and the images: PostgreSQL's is 420 MB on disk. Raise the VM's memory to 4 GB if it has less, because the tests run a JVM and a database side by side |
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

PLACEHOLDER-CHECKS
