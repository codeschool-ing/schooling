---
title: Your lab, on your own computer
version: 1
---

This course has sixteen machines in it: a head office with two routers, a file server and a laptop; a
branch with its router and a till; a home with its router and Ana's laptop; an ISP; a data centre with a
DNS server, two load balancers and three web servers; and an analyst's machine for capturing traffic. **You build all of them yourself, inside one Linux
machine, and every command in every lesson is typed there.** Nothing runs on a computer we host.

They are not twenty virtual machines. Each one is a **network namespace**: a copy of the Linux network
stack with its own interfaces, addresses, routes and firewall, inside one running system. A cable is a
pair of virtual Ethernet interfaces, and a switch is a Linux bridge. To the programs running on them,
they are separate machines; `tcpdump` on one sees only that machine's traffic, and a ping between two of
them crosses every router in between. The whole network takes about 70 MB of memory and 80 MB of disk,
and it builds in about ten seconds, so a lesson that breaks it is a lesson you can repeat.

What it needs is **one Linux machine where you are root**: Ubuntu 24.04, the system every transcript in
this course was recorded on. There are three ways to have one. Pick the virtual machine unless you have
a reason not to.

| | what it is | what it costs |
|---|---|---|
| installed | Ubuntu 24.04 on a computer of its own, or as the system of the one you use | nothing to buy, and twenty-six packages on that computer for good, a DNS server and a VPN server among them |
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu Server 24.04 machine with one command, on Windows, macOS and Linux | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| online | a small Linux server rented by the hour from a cloud provider | money for every hour it exists, and a machine on the internet from its first minute |

**Installed** works, and the network itself leaves nothing behind when you take it down. The packages
stay, though, and several of them are servers. A spare computer you can wipe is the right place; the
computer you use every day is not.

**The virtual machine** is the recommended path because it costs nothing and goes away with one
command. Multipass uses the hypervisor each system already has: Hyper-V on Windows, the macOS
virtualisation framework on a Mac, KVM on Linux. Any other hypervisor works too, with the Ubuntu Server
24.04 installer image and half an hour of installer screens: VirtualBox on Windows, Linux or an Intel
Mac, UTM on an Apple-silicon Mac, Hyper-V Manager on Windows, GNOME Boxes or virt-manager on Linux.

**Online** is named so that you know it exists. Any provider's smallest Ubuntu 24.04 server is enough.
The network the course builds never reaches the internet, so being online is not a risk to it, but the
server itself is, and it costs money for as long as it exists. Some providers have a free tier; this
course does not depend on one, because a free tier's terms are the provider's to change.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name netlab --cpus 2 --memory 2G --disk 10G
multipass shell netlab
```

**Those two commands were not run for this course**, because the computer it was recorded on cannot
run a hypervisor. The first creates the machine, called `netlab`, and the second opens a shell inside
it. Everything after this point happens in that shell, and the lessons often want two or three at
once, one per machine you are watching: open another terminal and run `multipass shell netlab` again.

## The packages

Every program the course uses comes from Ubuntu's own archive:

```sh
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iproute2 nftables bind9 bind9-dnsutils \
    nginx openssl tcpdump tshark traceroute mtr-tiny iperf3 netcat-openbsd curl iputils-ping \
    ethtool wireguard-tools wireguard-go openvpn strongswan-swanctl strongswan-charon \
    libcharon-extra-plugins keepalived haproxy python3 socat
```

`DEBIAN_FRONTEND=noninteractive` stops the installer from asking whether ordinary users may capture
packets; the script in the next section answers that question itself, more narrowly. Ubuntu starts some
of these servers as it installs them. They run in the machine's own network, outside every namespace,
so they never meet the copies the course starts inside its machines, each with its own configuration.
