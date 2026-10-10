---
title: Your lab
version: 1
---

Nothing in this course runs on a machine we host. **You build a Linux machine with Docker Engine
and Compose on it, and every command in every lesson is typed there.** The transcripts in the
lessons were recorded on one: Ubuntu 24.04, Docker Engine 29 from Docker's own packages, a user
called `ana` and a machine called `vm`. Your prompt will carry your own names. The answers will be
the same apart from the ids Docker invents, the timestamps and the timings.

This course needs more of the machine than `docker` did. A message broker, two or three
databases and a search engine are in some lessons at the same time, and Kafka and OpenSearch run
on the Java virtual machine, which takes memory before it does anything.

There are three ways to get that machine. Pick the virtual machine unless you have a reason not
to.

| | what it is | what it costs |
| --- | --- | --- |
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu 24.04 VM with one command, on Windows, macOS or Linux, with Docker Engine installed inside it | 4 processors, 8 GB of memory and 40 GB of disk while it runs; a computer with 16 GB of memory runs it comfortably beside a browser |
| installed | Docker Desktop on Windows or macOS, or Docker Engine straight on a computer that already runs Linux | Desktop runs a Linux VM of its own, sized in its settings, which needs the same 8 GB; Engine on the computer you use every day leaves every container this course starts on it |
| online | a GitHub Codespace, or Docker's own Play with Docker, in the browser | nothing on your computer; a monthly allowance of free hours, or a session deleted after four hours, that the company offering it decides and can change |

**The virtual machine is the same shape as the one the transcripts came from**, so when your
output differs from the lesson's, the difference is worth reading. It also costs nothing to lose:
a lesson that fills the disk or leaves twenty containers behind is a lesson you can repeat on a
fresh machine.

**Installed works for every lesson.** Docker Desktop's VM is the machine in that case, and you
size it in Desktop's settings under *Resources*: 4 processors and 8 GB. If your computer has 8 GB
in total, give the VM 6 and close the browser while lessons 6, 10 and 17 run; those are the ones
that start the JVM brokers and the search engine.

**Online is named so that you know it exists.** The smallest Codespace has 2 processors and 8 GB,
and a personal account's free allowance, as GitHub publishes it, is 120 core-hours a month: 60
hours of that machine. A Play with Docker session is deleted after four hours. No lesson here depends on a free tier that somebody else can change.

## With Multipass

If you followed `docker` lesson 5, you have a VM called `vm` already. Make a second, larger one
for this course, so that one can be thrown away without the other. Install Multipass from
Canonical's site, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name arch --cpus 4 --memory 8G --disk 40G
multipass shell arch
```

**These two commands were not run for this course**, because the machine it was recorded on is
itself a virtual machine and cannot start another. The first creates the VM and the second opens a
shell inside it, as the user `ubuntu`. Everything after this point happens in that shell.

## Docker Engine and Compose

Inside the VM, install Docker Engine from Docker's own repository. These are the commands from
Docker's installation instructions for Ubuntu, the same ones `docker` lesson 5 explained line by
line. They were not run here either, because the lab already had the result; check them against
Docker's documentation before you run them, since the details change:

```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

The last line puts you in the `docker` group, so `docker` works without `sudo`. **It takes effect
at your next login**: leave the shell with `exit` and run `multipass shell arch` again.

## The first checks

Three commands say whether the machine is ready. The first two name the versions; the third
pulls a small image and runs a program in it, which proves the engine, the network to the
registry and your permission on the socket in one go:

```
ana@vm:~$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
ana@vm:~$ docker compose version
Docker Compose version v5.6.0
ana@vm:~$ docker run --rm alpine:3.22 echo hello from a container
Unable to find image 'alpine:3.22' locally
3.22: Pulling from library/alpine
53f8f5e03afd: Pulling fs layer
53f8f5e03afd: Download complete
53f8f5e03afd: Pull complete
b2e1ce860133: Download complete
0629b44bdb87: Download complete
Digest: sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8
Status: Downloaded newer image for alpine:3.22
hello from a container
```

Your versions may be newer, which is fine. What matters is that `docker compose`, with a space,
answers: that is the Compose plugin the lessons use. The old `docker-compose`, with a hyphen, is a
different program and is not used here.

**Every lesson works in a directory of its own under `~/lab`**, named in the lesson. Make the
parent now:

```sh
mkdir -p ~/lab
```

Each lesson ends by stopping what it started, with `docker compose down -v` in its directory. The
`-v` removes the lesson's volumes as well, which is what you want: the next lesson starts from
nothing and builds what it needs.
