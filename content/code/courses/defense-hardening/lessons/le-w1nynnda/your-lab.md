---
title: Your lab, built by you
version: 1
---

Nothing in this course runs on a machine we host. **You build the lab yourself, and every command
in every lesson is typed there.** Hardening is a subject you learn by changing a system and then
checking what changed, and sometimes by breaking it, so the lab is made to be thrown away: one
command gives you a fresh copy of every machine in about a minute.

The lab is a small accounting firm, Jatobá Contabilidade, in seven machines on one network segment.
`web` is the firm's client portal, the server most of the course hardens. `desk` is a workstation,
`admin` is where an administrator works from, `jump` is the one door lesson 15 builds, `dns` is the
firm's name server, `trap` is the bait of lesson 13, and `sw` is the switch they are all plugged
into. All seven are containers on one Linux computer running **Ubuntu 24.04**, and that computer is
the only thing you need to provide.

There are three ways to get it. Pick the virtual machine unless you have a reason not to.

| | what it is | what it costs |
|---|---|---|
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu Server 24.04 machine with one command, on Windows, macOS and Linux | 2 processors, 4 GB of memory and 20 GB of disk while it runs |
| installed | Ubuntu 24.04 as the system of a computer you can spare | nothing to buy, and the lab's two packages and 8 GB of machines on that computer until you delete them |
| online | a small Ubuntu 24.04 machine rented by the hour from a cloud provider | money for as long as it exists |

**The lab asks for root on the computer it runs on**, and that is why a virtual machine comes first.
It creates network namespaces, boots containers and writes 8 GB under `/var/lib/hostlab`. In a
virtual machine all of that goes away with the machine, and a lesson that breaks the computer
itself, rather than one of the containers, costs you a new virtual machine and nothing else.
**Installed** is right only for a computer you can wipe afterwards.

Any other hypervisor works in place of Multipass, given an Ubuntu Server 24.04 LTS image and the same 2 processors, 4 GB and 20 GB.
That includes **VirtualBox** on Windows, Linux or an Intel Mac, **UTM** on an
Apple-silicon Mac, **Hyper-V** on Windows, **GNOME Boxes** or **virt-manager** on Linux. They cost
half an hour of installer screens that Multipass skips. **Online** is any provider that rents an
Ubuntu 24.04 machine with root access. A free tier will do if you have one, but nothing in the
course depends on it, and nothing the lab starts listens on that machine's public address: the
seven machines live on a network of their own that is connected to nothing.

A container will not do as the computer: not Docker, not LXD, and not the Linux shell some websites
open in a browser tab. The lab is made of containers, and only root on a whole machine, real or
virtual, may create them.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name hostlab --cpus 2 --memory 4G --disk 20G
multipass shell hostlab
```

**Those two commands were not run for this course**, because the computer it was recorded on is
itself a virtual machine and cannot run a hypervisor. The first creates the machine and the second
opens a shell inside it, as the user `ubuntu`. Everything after this point happens in that shell.
Wherever a transcript in this course says `ana`, your machines will say `ubuntu`, or whatever your
account is called.

## The two packages

The script that builds the lab needs two programs that a fresh Ubuntu Server does not have:
`debootstrap`, which downloads a minimal Ubuntu into a directory, and `systemd-nspawn`, which boots
one. Both come from Ubuntu's own archive:

```sh
sudo apt-get update
sudo apt-get install -y debootstrap systemd-container
```

Everything else the course uses is installed inside the machines by the script, from the same
archive, so the computer you chose stays as it was apart from these two and the lab's own
directory. The next section is the script.
