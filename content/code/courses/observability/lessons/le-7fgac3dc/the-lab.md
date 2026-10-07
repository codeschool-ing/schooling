---
title: Your lab, built by you
version: 2
---

Every command in this course was run, and every line of output is what it printed. **You build the
same lab on your own computer, and every command in every lesson is typed there.** Nothing in this
course runs on a machine we host.

The lab is one Linux machine running Docker: a small online shop, written for the course, and the
open-source software that watches it, each in its own container. The next two sections give you
every file of it. This one gets you the machine.

There are three ways to have that machine. Pick the virtual machine unless you have a reason not to.

| | what it is | what it costs |
|---|---|---|
| installed | Docker Engine on a Linux computer you already have | 4 processors and 8 GB of memory free while the lab runs, and about 15 GB of disk for the images |
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu Server 24.04 machine with one command, on Windows, macOS and Linux | the same 4 processors and 8 GB, given to the machine while it runs, and a 40 GB disk that grows as it fills |
| online | a virtual machine you rent by the hour from a cloud provider | money for every hour it exists, so it is deleted at the end of each session |

**The lab needs four processors and 8 GB of memory**, and that is the figure to plan for. Started
and left alone it uses about 900 MB, but the lessons run simulated customers against it for many
minutes at a time. Lesson 9 adds Elasticsearch and Graylog, and that one lesson wants 16 GB; on a
smaller computer its transcripts can be read rather than reproduced, and the lesson says which.

**Installed** is right on a Linux computer you can spare, or on the one you use every day if you
already run Docker on it: nothing here installs anything outside Docker, and every port is
published only to that computer itself. On Windows or macOS, Docker Desktop runs Linux in a hidden
virtual machine of its own. It may well run the whole lab, but the course was not recorded on it,
and when something differs you are debugging a machine you cannot see. The recommended path avoids
that question. **Online** works too, and every cloud's smallest machines are too small for
this lab; one with four processors and 8 GB costs real money per hour, so delete it when you stop
rather than leaving it running. The `cloud` course, which this one requires, is where creating
one is taught. Any other hypervisor works in place of Multipass as well: VirtualBox, UTM on an
Apple-silicon Mac, Hyper-V on Windows or GNOME Boxes on Linux, at the price of half an hour of
installer screens and the Ubuntu Server 24.04 image downloaded by hand.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name obs --cpus 4 --memory 8G --disk 40G
multipass shell obs
```

**Those two commands were not run for this course**, because the computer it was recorded on cannot
run a hypervisor; it is an Ubuntu 24.04 machine of its own. The first creates the virtual machine
and the second opens a shell inside it, as the user `ubuntu`. Everything after this point happens
in that shell.

## Docker, from Docker's own packages

Ubuntu's archive carries an older Docker under another name, so the course installs Docker Engine
and its Compose plugin from Docker's repository, as Docker's documentation says to, together with
`jq`, which the lessons use to read JSON:

```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl jq
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

The last line puts you in the `docker` group, which is what lets you talk to Docker without `sudo`.
**It takes effect at your next login**, so leave the shell with `exit` and open it again with
`multipass shell obs`. Then `docker compose version` should answer with a version. This course was
recorded with Docker Engine 29.8 and Compose 5.6; a newer one prints the same things.

## The names in the transcripts

The machine this course was recorded on is called `obs`, its user is `ana`, and the lab lives in
`~/shop`, so every transcript starts with `ana@obs:~/shop$`. Yours says `ubuntu@obs` if you used
Multipass, or your own name on a computer of your own. That is the only difference you should see,
apart from the parts that differ on every run: dates, durations to the millisecond, and the random
ids every trace gets.
