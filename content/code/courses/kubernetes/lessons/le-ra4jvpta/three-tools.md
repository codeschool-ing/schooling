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

## Which path

Lesson 1 already made this choice: Docker, `kind` and `kubectl` in an Ubuntu virtual machine, or
straight on a computer that runs Linux, with a browser playground named as the third path and not
relied on. Nothing here changes it. The next section builds a cluster by hand, called `study`, from
the same kind of file `up.sh` uses, and measures what it costs in memory. The section after it breaks the setup on purpose, because that is where most people give up, and it is almost always
one of four errors.
