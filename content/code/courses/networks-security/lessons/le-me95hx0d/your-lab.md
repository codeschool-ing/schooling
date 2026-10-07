---
title: Your lab, built by you
version: 1
---

Nothing in this course runs on a machine we host. **You build the lab yourself, and every command in
every lesson is typed there.** The lab is a small company's network: a firewall, eleven more machines
in six segments around it, and the services they run. All of it lives inside one Linux computer, so a
single Ubuntu 24.04 machine is all you need. Building the whole network takes a few seconds, and a
lesson that breaks something is a lesson you can start again.

There are three ways to get that machine. Pick the virtual machine unless you have a reason not to.

| | what it is | what it costs |
|---|---|---|
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu Server 24.04 machine with one command, on Windows, macOS and Linux | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| installed | Ubuntu 24.04 as the system of a computer you can spare | nothing to buy, and every package on the list below installed on that computer for good |
| online | a small Ubuntu 24.04 machine rented by the hour from a cloud provider | money for as long as it exists |

**The lab changes the computer it runs on**, and that is why a virtual machine comes first. It needs
32 packages, nginx, BIND and Suricata among them; it keeps its machines under `/lab`, puts one
command in `/usr/local/bin`, and adds the lab's own certificate authority to the list of authorities
the computer trusts. In a virtual machine all of that goes away with the machine. **Installed** is
right only for a computer you can wipe afterwards.

Any other hypervisor works in place of Multipass, with an Ubuntu Server 24.04 LTS image and the same
2 processors, 2 GB and 10 GB: **VirtualBox** on Windows, Linux or an Intel Mac, **UTM** on an
Apple-silicon Mac, **Hyper-V** on Windows, **GNOME Boxes** or **virt-manager** on Linux. They cost
half an hour of installer screens that Multipass skips. **Online** is any provider that rents an
Ubuntu 24.04 machine with root access. A free tier will do if you have one, but nothing in the course
depends on it. Nothing the lab starts listens on the machine's public address; every service runs
inside the lab's own machines.

A container will not do: not Docker, and not the Linux shell some websites open in a browser tab.
The lab creates network namespaces, and only root on a whole machine, real or virtual, may create
them.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name nslab --cpus 2 --memory 2G --disk 10G
multipass shell nslab
```

**Those two commands were not run for this course**, because the computer it was recorded on is
itself a virtual machine and cannot run a hypervisor. The first creates the machine and the second
opens a shell inside it, as the user `ubuntu`. Everything after this point happens in that shell.

## The packages

Every program the lab uses comes from Ubuntu's own archive, so one `apt-get` installs them all:

```sh
sudo apt-get update
sudo apt-get install -y iproute2 nftables conntrack tcpdump openssl nginx \
    libnginx-mod-http-modsecurity modsecurity-crs suricata jq wireguard-tools wireguard-go \
    dnsmasq-base bind9 bind9-dnsutils unbound netcat-openbsd curl iputils-ping iputils-arping \
    socat openssh-server ulogd2 ulogd2-json rsyslog aide hostapd wpasupplicant python3 \
    python3-cryptography python3-cffi-backend ethtool
```

On the computer the course was recorded on, which already had a few of them, that was 134 packages:
30 MB to download and 109 MB on disk. `dnsmasq-base` is the name server program without the service
that would start it on the computer itself; the lab starts its own copy inside its machines, and so
it does with every other server on that list.

The next section is the script that builds the network.
