---
title: The machine you will type on
version: 1
---

Nothing in this course runs on a machine we host. **You build a Linux machine with Docker Engine on
it, and from this lesson on every command is typed there.** Every transcript in the course was
recorded on one, which the lessons call the lab: Ubuntu 24.04 with Docker Engine 29 from Docker's
own packages, a user called `ana` and a machine called `vm`. Your prompt will carry your own name. The answers are the same, apart
from the ids Docker invents and the timings, which differ on every run anyway.

There are three ways to get that machine. Pick the virtual machine unless you have a reason not to.

| | what it is | what it costs |
| --- | --- | --- |
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu 24.04 VM with one command, on Windows, macOS or Linux, and Docker Engine installed inside it | 2 processors, 4 GB of memory and 30 GB of disk while it runs; on your own system, only Multipass itself |
| installed | Docker Desktop on Windows or macOS, the rest of this lesson; or Docker Engine straight on a computer that already runs Ubuntu, lesson 6 | Desktop runs a Linux VM of its own, sized in its settings, and needs a paid licence at a large company; Engine on the computer you use every day makes everybody in the `docker` group root on it, as lesson 6 shows |
| online | Play with Docker, Docker's own playground, or a GitHub Codespace, in the browser | nothing on your computer; a session that is deleted after a few hours, or a monthly allowance of free hours that the company offering it decides |

**The virtual machine is the same shape as the one the transcripts came from**, so when your output
differs from the lesson's, the difference is worth reading rather than a side effect of the setup.
It also costs nothing to lose. A lesson that breaks the daemon is a lesson you can repeat on a fresh
machine, and Ubuntu, Docker and the tools are all that is on it.

**Installed works for nearly every lesson.** With Docker Desktop, the daemon, its configuration file
and `/var/lib/docker` live inside Desktop's own VM, which you never log into. The parts of lessons
3, 4, 6 and 28 that look at them from the host are then to be read rather than repeated. Engine
on your own Ubuntu computer is exactly the lab, minus the freedom to throw it away.

**Online is named so that you know it exists, not recommended.** From lesson 11 on you build one
project, `shelf`, and keep changing it for sixteen lessons. A session that is deleted takes it with
it, and no lesson here depends on a free tier that somebody else can change.

On a Mac with Apple silicon, Multipass makes an `arm64` machine. Every image this course uses is
published for `arm64`, so the commands work unchanged. The two lessons about the processor, 2 and
13, read the other way round on it: what fails on the lab's `amd64` runs on yours, and the reverse.

## With Multipass

Install Multipass from Canonical's site. It drives a hypervisor the system already has: Hyper-V on
Windows, or VirtualBox on editions without Hyper-V; QEMU over Apple's own hypervisor on macOS; and
QEMU with KVM on Linux. Then, in your computer's own terminal:

```sh
multipass launch 24.04 --name vm --cpus 2 --memory 4G --disk 30G
multipass shell vm
```

**These two commands were not run for this course**, because the machine it was recorded on is
itself a virtual machine and cannot start another. The first creates the VM and the second opens a
shell inside it, as the user `ubuntu`. Everything after this point happens in that shell.

Any other hypervisor works in place of Multipass: VirtualBox, UTM on an Apple-silicon Mac, Hyper-V
or GNOME Boxes, with an Ubuntu Server 24.04 LTS installer and the same sizes. It costs half an hour of
installer screens instead of one command.

## Docker Engine, and the tools around it

Inside the VM, Docker Engine comes from Docker's own package repository. Lesson 6 explains these
lines one at a time; they are the commands from Docker's installation instructions for Ubuntu, and
Docker's documentation is the place to check them first, since the details change:

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

Two more lines. The first lets your user run `docker` without `sudo`, which lesson 6 weighs before
you rely on it. The second installs what the lessons use beside Docker: `jq`, which reads JSON, and
`psql`, PostgreSQL's command-line client. Ubuntu already has `git` and `curl`.

```sh
sudo usermod -aG docker $USER
sudo apt-get install jq postgresql-client
```

**A new group takes effect at the next login**, so leave the shell with `exit` and open it again
with `multipass shell vm`. The lab machine had all of this before the course began, so none of the
commands above was run for it. What it does show is how the result is checked:

```
ana@vm:~$ jq --version && psql --version && git --version
jq-1.7
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
git version 2.43.0
ana@vm:~$ id -nG
ana docker
```

`docker` in the list of groups means the new login took. Then come the four checks two sections
down, and those decide whether the engine works.
