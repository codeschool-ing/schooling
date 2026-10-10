---
title: Your machine
version: 1
---

Nothing in this course runs on a machine we host. **You build the machine yourself, and every command
in every lesson is typed there.** It is one Ubuntu 24.04 machine with Python, `curl`, SQLite and a
handful of libraries installed from Ubuntu's own archive. You can throw it away and build it again in
about twenty minutes, which is the property that matters most: a lesson that leaves something broken
is a lesson you can start again from nothing.

There are three ways to get that machine. Pick the virtual machine unless you have a reason not to.

| | what it is | what it costs |
|---|---|---|
| installed | the packages straight onto Ubuntu 24.04, either a computer of its own or WSL on Windows | nothing extra, and every package of the next section stays on that system for good |
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu VM with one command, on Windows, macOS and Linux | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| online | a small Linux machine you rent by the hour from a cloud provider | money, and a machine on the internet from its first minute |

**The virtual machine** is recommended because it is the same everywhere. The transcripts in these
lessons were recorded on Ubuntu 24.04 with exactly the packages the next section installs, and a VM is
the one way to have that on any computer without touching the system you work on. Any other
hypervisor works in place of Multipass, VirtualBox, UTM on an Apple-silicon Mac, Hyper-V or GNOME
Boxes, at the price of half an hour of installer screens.

**Installed** is a fine choice if you already run Ubuntu 24.04, or WSL with the Ubuntu 24.04
distribution on Windows. On macOS, or on another Linux, the same programs exist, but the versions
will differ from the transcripts, and the libraries will come from `pip` instead of `apt`; expect to
read an output that is not quite the one printed here. **Online** is named so that you know it exists,
not recommended: the servers in this course listen only on `127.0.0.1`, so they are safe on a public
machine, but you would be paying by the hour for something your own computer does for free.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name api --cpus 2 --memory 2G --disk 10G
multipass shell api
```

**Those two commands were not run for this course**, because the computer it was recorded on cannot
run a hypervisor; the machine in the transcripts was built from the same Ubuntu release and the same
packages without one. The first command creates the virtual machine and the second opens a shell
inside it. Everything after this point happens in that shell.

Two small differences from the transcripts are expected and harmless. The prompt here reads
`ana@api`, and yours will read `ubuntu@api`, because Multipass names its user `ubuntu`. And the
`multipass shell api` command is also how you open the second terminal that lesson 1's server needs:
run it again in another window, and you are on the same machine twice.
