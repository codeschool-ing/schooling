---
title: Installing Docker
version: 1
---

Lesson 16 built a server by hand: packages, a virtual environment, an environment file, units. A
**container image** packs the application and everything it needs to run into one file-system
snapshot, and the same image runs on a laptop, a CI runner and a server. The `docker` course teaches
Docker itself; this lesson uses it for agenda.

## Three places to have it

| path | what you get | what it costs your computer |
|---|---|---|
| **in your virtual machine** (recommended) | Docker Engine from Docker's own repository for Ubuntu, as the `docker` course installs it | the engine, and the images it stores, a few gigabytes over time |
| **installed on your own computer** | Docker Desktop for Windows or macOS, which runs a Linux virtual machine of its own | the same, plus that virtual machine; Docker Desktop's licence asks larger companies to pay |
| **online** | a platform that builds and runs a Dockerfile for you | nothing; the platform decides the network, the volumes and the logs |

**The virtual machine is the one to pick**: Docker's packages for Ubuntu are the ones the `docker`
course uses and checks, and the commands below are Linux's.

## Installing it

In the virtual machine, Docker's repository and then the packages, exactly as the `docker` course's
first lesson gives them:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

The last line lets you run `docker` without `sudo`. **Membership of the `docker` group is as good as
root on that machine**, which the `docker` course shows at length; on a virtual machine of your own
that is acceptable. It takes effect at the next login:

```
ana@vm:~$ docker --version
Docker version 29.8.2, build 7fc2dff
ana@vm:~$ docker compose version
Docker Compose version v5.6.0
ana@vm:~$ id -nG
ana docker
ana@vm:~$ docker run --rm hello-world | head -2
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
4f55086f7dd0: Pulling fs layer
4f55086f7dd0: Download complete
4f55086f7dd0: Pull complete
d5e71e642bf5: Download complete
Digest: sha256:11a3eb1597e864c51b3f56733cb2e8a90bf0c284bfc05f9444d81c558bc848aa
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
```

## When it fails

| symptom | cause | fix |
|---|---|---|
| `permission denied while trying to connect to the Docker daemon socket` | the group change has not taken effect | log out and in again; `id -nG` must list `docker` |
| `Cannot connect to the Docker daemon` | the engine is not running | `sudo systemctl start docker` |
| `toomanyrequests` when pulling | Docker Hub's limit for anonymous pulls | `docker login`, or wait; the `docker` course shows a mirror |

These were not produced for this course; the messages are Docker's for those causes.
