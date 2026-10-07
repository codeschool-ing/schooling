---
title: Your lab, built by you
version: 1
---

Every transcript in this course was printed by a real network, and you build that network yourself,
on your own computer. It is not a rack of equipment. **It is one Linux machine running Ubuntu 24.04,
on which one script builds each network the course needs out of pieces of the Linux kernel**: a
network namespace for each device, a virtual cable between two of them, a bridge inside a namespace
for each switch, and FRR, the open-source routing suite, for the routers. A whole office with its
switch, router and provider fits in one machine, and none of it touches the network your computer is
really on.

There are three ways to get that machine. Pick the virtual machine unless you have a reason not to.

| | what it is | what it costs |
|---|---|---|
| installed | Ubuntu 24.04 on a computer of its own | nothing to buy, and a routing suite, a DHCP server and some twenty network tools installed on that computer for good |
| **a virtual machine** (recommended) | Ubuntu Server 24.04 LTS in a hypervisor on the computer you already use | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| online | a small Linux virtual machine rented from a cloud provider | money by the hour, for as long as it exists |

**The virtual machine is the one to choose** because the lab runs as root, loads kernel modules and
creates and deletes dozens of interfaces, and a machine you can delete and make again in half an hour
is the right place for that. The figures in the table are generous: on the machine this course was
recorded on, the busiest network of the course used about 60 MB of memory more than the idle system,
and the packages took under 300 MB of disk.

The hypervisor depends on the computer you have. **Multipass**, Canonical's tool, makes an Ubuntu
virtual machine with one command on Windows, macOS and Linux, and it is the shortest path:

```sh
multipass launch 24.04 --name netlab --cpus 2 --memory 2G --disk 10G
multipass shell netlab
```

The first command downloads Ubuntu and creates the machine, and the second opens a shell inside it, as
the user `ubuntu`. Any other hypervisor works as well, at the price of the installer's screens:
VirtualBox on Windows and Linux, UTM on a Mac, Hyper-V on Windows Pro, GNOME Boxes or virt-manager on
Linux. Install Ubuntu Server 24.04 LTS in it, with the OpenSSH server if the installer offers it. On a
Mac with an Apple processor, choose the ARM edition of Ubuntu Server; the packages the lab needs are
built for it too.

**Those two Multipass commands were not run for this course.** It was recorded on an Ubuntu Server
24.04 virtual machine made with QEMU from Ubuntu's own cloud image, on a computer with no hardware
virtualisation, so the processor was emulated in software. Everything worked, more slowly than it will
for you: building one network took between 20 and 51 seconds there.

**Installed** is right if you have a spare computer you can wipe. On the one you use every day it is
the wrong choice, for the same reason the virtual machine is the right one. **Online** is named so you
know it exists. Any provider's smallest machine with Ubuntu 24.04 will do, and the lab never exposes a
service to the internet, because every address in it is private or reserved for documentation. But it
costs money for as long as it exists, and no lesson in this course depends on a provider's free tier.

**A container is not a lab.** WSL2 on Windows and a Docker container both give you an Ubuntu shell,
and both run on a kernel that came with them, which usually lacks modules and cannot be given new ones. The lab asks for five:
`veth` for the cables, `bridge` for the switches, `8021q` for VLANs, `bonding` for lesson 21's bundled
cables and `wireguard` for lesson 4's tunnel. The section on failures shows what a container answers.

The prompts in this course were recorded on that virtual machine, whose name is `lab` and whose user
is `ana`. Yours will show your own names: `ubuntu@netlab` under Multipass, for example. The next
section puts the lab on the machine.
