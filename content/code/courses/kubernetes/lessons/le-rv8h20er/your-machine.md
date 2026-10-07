---
title: Your machine is the lab
version: 1
---

**Everything this course shows, you run yourself, on a computer of your own.** Nobody hands you a
cluster: from lesson 2 on, every lesson starts by building a fresh one in a few seconds, with the
same three programs every transcript was recorded with. Docker runs the nodes, `kind` builds the
cluster out of them, and `kubectl` talks to it. This section installs them, the next one builds the
application the lessons deploy, and the end of this lesson builds the cluster.

## Three paths

| path | what it is | what it costs your computer |
|---|---|---|
| installed | Docker, `kind` and `kubectl` on a computer that already runs Linux | about 1 GiB of memory while a cluster runs, and 3 GiB of disk for the images |
| **a virtual machine with Multipass** (recommended) | Ubuntu Server 24.04 in a VM made with one command, on Windows, macOS or Linux, and the same three programs inside it | 4 processors, 6 GiB of memory and 30 GiB of disk while it runs |
| online | a Kubernetes playground in the browser, such as Killercoda, or a Linux VM rented by the hour | nothing on your computer; the playground forgets everything after a session, and the rented VM costs money |

**The virtual machine is the recommendation**, because the lessons are written for Linux and a few of
them reach past `kubectl` into the machine underneath: lesson 1 kills a container's process by its
number, and lesson 15 calls addresses on Docker's own network. Inside an Ubuntu VM all of that
works the same on every host. Multipass, Canonical's tool, makes the VM with one command and drives
whichever hypervisor your system has: Hyper-V on Windows (VirtualBox on Windows Home), the built-in
virtualisation framework on macOS, and KVM on Linux. Any other hypervisor works too, VirtualBox, UTM
on an Apple-silicon Mac or GNOME Boxes, at the price of an installer to click through.

**Installed** is the same thing without the VM, and it is the better choice if your computer already
runs Ubuntu or another Linux: nothing below changes except that you skip the next two commands.
Docker Desktop on Windows or macOS can also run `kind`, and most lessons work there, but the
addresses of lesson 15 live inside Docker Desktop's own VM and cannot be reached from the
host. **Online** is named so you know it exists. A playground is a good way to try one command and a
poor way to follow a course, because each session starts empty and every lesson here rebuilds its
cluster anyway; no lesson depends on any company's free tier.

## The virtual machine

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name k8s --cpus 4 --memory 6G --disk 30G
multipass shell k8s
```

**Those two commands were not run for this course**, because the computer it was recorded on cannot
run a hypervisor. The first creates the VM and the second opens a shell inside it, as the user
`ubuntu`. Everything after this point happens in that shell. With less memory, 4 GiB works for every
lesson except the few that fill a node on purpose, which then fill it sooner.

## Docker

The `docker` course installs Docker Engine in lesson 6, from Docker's own package repository. If you
did that course on this machine, skip ahead. The short version, from Docker's installation
instructions for Ubuntu, is:

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

The last line lets you use `docker` without `sudo`, and it takes effect at your next login: leave
the shell with `exit` and open it again with `multipass shell k8s`. These commands were not run here
either, because the recording machine already had Docker; this is what it has:

```
ana@laptop:~/shop$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
```

## kind and kubectl

The transcripts in this course were recorded as `ana`, on a machine called `laptop`, in a directory
`~/shop`. Make yours now with `mkdir ~/shop && cd ~/shop`. Your prompt will say `ubuntu@k8s` if you
took the VM, and that is the only difference you should see.

Both programs are single files, downloaded from their projects and checked against the checksum each
project publishes beside the file. `ARCH` is `amd64` on most computers and `arm64` on an
Apple-silicon Mac, and `dpkg` knows which:

```
ana@laptop:~/shop$ ARCH=$(dpkg --print-architecture); echo $ARCH
amd64
ana@laptop:~/shop$ curl -fsSLo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH
ana@laptop:~/shop$ curl -fsSL https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH.sha256sum | sed "s/kind-linux-$ARCH/kind/" | sha256sum --check
kind: OK
ana@laptop:~/shop$ curl -fsSLo kubectl https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl
ana@laptop:~/shop$ echo "$(curl -fsSL https://dl.k8s.io/release/v1.37.1/bin/linux/$ARCH/kubectl.sha256)  kubectl" | sha256sum --check
kubectl: OK
ana@laptop:~/shop$ sudo install -m 0755 kind kubectl /usr/local/bin/ && rm kind kubectl
ana@laptop:~/shop$ kind version
kind v0.33.0 go1.26.7 linux/amd64
ana@laptop:~/shop$ kubectl version --client
Client Version: v1.37.1
Kustomize Version: v5.8.1
```

**Two `OK`s are the point of the middle lines**: the file you downloaded is the file the project
published. A failed check prints `FAILED` and exits with an error, and the right response is to
delete the file and download it again, never to install it anyway.
