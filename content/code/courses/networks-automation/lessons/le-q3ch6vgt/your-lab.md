---
title: Your lab, and three ways to have one
version: 1
---

Every command in this course was run, and every line of output is what the command printed. **You
run them too, on a lab you build yourself in this lesson.** Nothing runs on a machine we host.

The lab is a small network: three routers running OSPF between them, a device managed only through
its data model, NetBox, a service desk, an OpenFlow switch, a few computers to test from, and
`ctl`, the automation host where you work. Buying that would cost a rack. Here it costs one Linux
machine, because each of those devices is a **network namespace**: a copy of the Linux network
stack with its own interfaces, addresses and routes, joined to the others by virtual cables. The
routing software is real, the APIs are real, and the packets really travel between namespaces;
what is missing is only the hardware.

That one machine must run **Ubuntu 24.04 LTS**. The routers are FRR from Ubuntu's own packages, and
the transcripts in the lessons were made with exactly the versions Ubuntu 24.04 ships.

| path | what it is | what it costs your computer | the transcripts |
|---|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04 in a VM made with Multipass | 2 processors, 4 GB of memory and 20 GB of disk while it runs | match as printed |
| installed | Ubuntu 24.04 as the system of a computer you can spare | nothing extra, and nine machines' worth of services added to that computer | match as printed |
| online | an Ubuntu 24.04 server rented by the hour from a cloud provider | nothing; the provider charges by the hour | match as printed |

Those sizes have room in them, and the room was measured. On the machine this course was recorded
on, the whole lab used 830 MB of memory with NetBox and every other service running. On disk, the
two Python environments it installs take 214 MB and 542 MB, Clixon's source 51 MB and NetBox's
saved database 84 MB, with Ubuntu's packages on top. The rest of the 4 GB is for Ubuntu itself and for
compiling Clixon in lesson 3. Multipass's own default disk, 5 GB, is too small.

**The virtual machine is the recommended path.** The lab installs routing software, a
database, a cache and a software switch, and it needs `sudo` to build namespaces. All of that is
better kept inside a machine you can delete. **Multipass**, Canonical's tool, makes an Ubuntu VM
with one command on Windows, macOS and Linux. Any other hypervisor works in its place, at the price
of going through an installer: VirtualBox on Windows and Linux, UTM on an Apple-silicon Mac,
Hyper-V on Windows Pro, GNOME Boxes on Linux. On an Apple-silicon Mac the virtual machine is ARM
rather than x86; Ubuntu's packages and the Python libraries exist for both, and the one download
in lesson 4 says which to pick.

**Installed** is right on a spare computer that already runs Ubuntu 24.04. On the computer you use
every day it is the wrong choice, because everything the lab installs stays installed.

**Online** is any provider that rents an Ubuntu 24.04 server: the big three clouds and the smaller
hosting companies all do. Some offer a free allowance for new accounts, and its terms are theirs to
change, so no lesson depends on one. A rented server is on the internet from its first minute; the
lab itself never listens on its public address, but keep the server's own SSH locked to a key.
This course was recorded on a machine of exactly this kind.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```
$ multipass launch 24.04 --name netlab --cpus 2 --memory 4G --disk 20G
$ multipass shell netlab
```

**Those two commands were not run for this course**, because the computer it was recorded on
cannot run a hypervisor. The first makes the virtual machine and the second opens a shell inside
it, as the user `ubuntu`, on a machine called `netlab`. Everything after this point is typed in
that shell.

## The software

Everything but four programs comes from Ubuntu's archive, so one `apt-get` installs it: FRR and its
reload tool, OpenSSH, Open vSwitch, Ansible, PostgreSQL and Redis for NetBox, and the small tools
the lessons use.

```sh
sudo apt-get update
sudo apt-get install -y frr frr-pythontools openssh-server openvswitch-switch python3-venv \
    ansible yamllint git curl jq openssl postgresql redis-server libyang-tools libxml2-utils \
    iproute2 iputils-ping traceroute netcat-openbsd python3-paramiko
```

Ubuntu starts some of those as services of the virtual machine itself. The lab runs its own copies
inside its machines and never uses these, so stop them and keep the memory:

```sh
sudo systemctl disable --now frr postgresql redis-server openvswitch-switch
```

**That line was not run for this course**: the machine it was recorded on has no systemd, so
nothing was started in the first place.

The Python libraries go in a **virtual environment**, a directory with its own Python and its own
packages, so nothing here touches the Python Ubuntu runs on. It lives in `/opt/netauto`, outside
anybody's home, because the lab's machines share it. The versions are pinned, because a newer
library can print something differently from the transcript you are reading:

```sh
sudo python3 -m venv /opt/netauto
sudo /opt/netauto/bin/pip install netmiko==4.8.0 napalm==5.2.0 nornir==3.6.0 nornir-netmiko==1.0.1 \
    nornir-napalm==0.6.0 nornir-utils==0.3.0 nornir-netbox==0.3.0 ncclient==0.7.0 pygnmi==0.8.15 \
    paramiko==5.0.0 Jinja2==3.1.6 pyang==2.7.1 requests==2.34.2 pytest==9.1.1 PyYAML==6.0.3 \
    xmltodict==1.0.4 grpcio==1.84.0 pynetbox==7.8.0 ansible-pylibssh==1.4.0 os-ken==4.2.2
```

The four programs that are not in the archive arrive with the lessons that use them: Clixon in
lesson 3, `gnmic` in lesson 4, OpenConfig's models in lesson 5 and NetBox in lesson 12. Each of
those lessons gives the commands where they are first needed.
