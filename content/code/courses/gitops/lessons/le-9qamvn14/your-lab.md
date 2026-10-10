---
title: Your machine is the lab
version: 1
---

**Everything this course shows, you run yourself, on a computer of your own.** Nobody hands you a
cluster or a Git server. This lesson builds the base that every later one uses: Docker, a one-node
Kubernetes cluster made by `kind`, an image registry beside it, and `kubectl`. Lesson 2 adds a Git
server in a container, and each later lesson installs the one tool it is about, with the commands
to do it, in the section that first needs it:

| lesson | what it adds |
|---|---|
| 1 | Docker, `kind`, `kubectl`, the registry, the cluster |
| 2 | Gitea, a Git server, in a container |
| 3 | Argo CD in the cluster, and its `argocd` command |
| 4 | Flux in the cluster, and its `flux` command |
| 6 | `helm` |
| 8 | `cosign` |
| 9 | the Sealed Secrets controller and `kubeseal`; `sops` and `age`; Vault, in a container, and its `vault` command |
| 10 | the External Secrets Operator |
| 11 | PostgreSQL, in a container |

Everything on that list is free software, and none of it needs an account anywhere.

## Three paths

| path | what it is | what it costs your computer |
|---|---|---|
| installed | the tools on a computer that already runs Linux | about 0.6 GiB of memory for the cluster and the registry, 1.7 GiB from lesson 3 on, and about 10 GiB of disk for the images |
| **a virtual machine with Multipass** (recommended) | Ubuntu Server 24.04 in a VM made with one command, on Windows, macOS or Linux, with the same tools inside it | 4 processors, 8 GiB of memory and 40 GiB of disk while it runs |
| online | a Linux virtual machine rented by the hour from any cloud provider | nothing on your computer; money for every hour it exists, and it must be deleted when you stop |

**The virtual machine is the recommendation**, because everything here is written for Linux and
some of it reaches past `kubectl` into the machine underneath: the node is a Docker container you
`docker exec` into, and the registry and Gitea are reached by container name from inside the
cluster. In an Ubuntu VM that works the same on every host. Multipass, Canonical's tool, makes the
VM with one command and drives whichever hypervisor your system has: Hyper-V on Windows (VirtualBox
on Windows Home), the built-in virtualisation framework on macOS, and KVM on Linux. Any other
hypervisor works too, VirtualBox, UTM on an Apple-silicon Mac or GNOME Boxes, at the price of an
installer to click through. The `virtualization` course builds one by hand in lesson 4.

**Installed** is the same thing without the VM, and it is the better choice if your computer already
runs Ubuntu or another Linux: nothing below changes except that you skip the next two commands.
Docker Desktop on Windows or macOS also runs `kind`, and most of the course works there, but the
names of containers on Docker's network are not reachable from your own terminal, and a few
commands that read them fail.

**Online** works and costs money. Any provider's smallest machine with 4 processors and 8 GiB will
run the course, and the commands are the ones below, typed over SSH. It is named so that you know it
exists; no lesson depends on it, and a machine left running bills you whether you use it or not.

## The virtual machine

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name gitops --cpus 4 --memory 8G --disk 40G
multipass shell gitops
```

**Those two commands were not run for this course**, because the computer it was recorded on cannot
run a hypervisor. The first creates the VM and the second opens a shell inside it, as the user
`ubuntu`. Everything after this point happens in that shell. With 6 GiB of memory every lesson
still works, as long as you do not keep Argo CD and Flux running at the same time; lesson 4 says
when to remove one.

A snapshot of the VM once the next section works, with `multipass stop gitops` and then
`multipass snapshot gitops`, gives you a clean start whenever an experiment goes wrong.
