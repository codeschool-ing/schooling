---
title: Three ways to have a cluster on your own machine
version: 1
---

**A study cluster does not have to be small in what it teaches.** The API, the objects, the
scheduler and the kubelet are the same programs a production cluster runs; what a laptop lacks is
hardware, not Kubernetes. Three free tools build one, and they differ mostly in what a "node" is
made of.

| | a node is | made by | best at |
|---|---|---|---|
| **kind** | a Docker container | the Kubernetes project, to test Kubernetes itself | several nodes, quickly, the same everywhere |
| minikube | a virtual machine or a container | the Kubernetes project | one node with add-ons switched on by name |
| k3d | a Docker container running k3s | the k3d community, around SUSE's k3s | a light distribution with fewer moving parts |

**This course uses kind, and every transcript in it was recorded with kind.** Its nodes are
containers, so creating a cluster takes seconds rather than the minutes a virtual machine needs,
and a cluster of three nodes is a configuration file of a dozen lines. It is what Kubernetes' own
test suite runs on, so the version you ask for is the version you get, unmodified. minikube and k3d
are named here so that you recognise them in somebody else's instructions; they were not run for
this course.

Docker Desktop can also switch on a cluster of its own, from its settings. It is the shortest path
on Windows and macOS, and it is one cluster with one name, which is limiting by lesson 48.

## Three paths, and what each costs your computer

| path | what you install | what it costs | when to take it |
|---|---|---|---|
| **on your machine** (recommended) | Docker, `kind`, `kubectl` | about 0.8 GiB of memory for three nodes, measured in the next section | almost always |
| in a Linux virtual machine | a VM with 4 GiB or more, then the same three | the VM's memory on top, and its disk | your machine runs something that conflicts with Docker, or you want the lab kept apart |
| online, in the browser | nothing | nothing, and the session is deleted after an hour or so | a machine you may not install on; nothing survives between sessions |

The browser path is a playground such as Killercoda, which hands you a fresh cluster in a tab. It
is a good way to try a command and a poor way to follow a course, because every lesson starts by
rebuilding what the last one left.

The next two sections build the recommended one and then break it, because the setup is where most
people give up, and it is almost always one of four errors.
