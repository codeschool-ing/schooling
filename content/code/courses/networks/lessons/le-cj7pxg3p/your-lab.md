---
title: Your lab, on your computer
version: 1
---

Nothing in this course runs on a machine we host. **You build the network in the drawing above
yourself, and every command in every lesson is typed there.** It is one Linux machine running
Ubuntu 24.04, with thirteen small machines inside it, built by four files that the next four
sections show in full. You can tear it down and build it again in about ten seconds. That matters
more than anything else here: a lesson that breaks the network is a lesson you can repeat.

There are three ways to get that Linux machine. Pick the virtual machine unless you have a reason
not to.

| | what it is | what it costs |
|---|---|---|
| installed | Ubuntu 24.04 as the system of a computer | nothing to buy; on a computer you use for anything else, the changes listed below, for good |
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu Server 24.04 machine with one command, on Windows, macOS and Linux | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| online | a small virtual machine rented by the hour from a cloud provider | money for every hour it exists, and a machine on the internet from its first minute |

**Installed** is right on a spare computer you can wipe, and wrong on the one you use every day.
The lab installs ten server packages, creates four accounts whose passwords are printed in this
course (`ana`, `bruno`, `example`, `scans`, with `ana` allowed to use `sudo`), adds a test
certificate authority to the system's trust store, and edits the SSH server's login settings. In a
virtual machine none of that touches your own system. **Online** works because the lab needs no
network of its own, only a Linux machine with root. Any provider will do; a free tier is a
convenience, not something this course depends on, and the machine should be deleted when you stop
for the day. In place of Multipass any hypervisor runs the same Ubuntu Server 24.04 installer
image: Hyper-V or VirtualBox on Windows, UTM on a Mac with Apple silicon, GNOME Boxes or
virt-manager on Linux. A container is the one thing that does not work, for a reason the section
on failures shows: building the lab means creating network namespaces, and a container is usually
not allowed to.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name netlab --cpus 2 --memory 2G --disk 10G
multipass shell netlab
```

**Those two commands were not run for this course**, because the computer it was recorded on
cannot run a hypervisor. The first creates the machine and the second opens a shell inside it, as
the user `ubuntu`, at a prompt that says `ubuntu@netlab`. Everything after this point happens in
that shell. On another hypervisor, install Ubuntu Server 24.04 from its image, call the machine
`netlab`, and give your own account any name but `ana`, which the lab creates for itself.

## Switching IPv6 off

The computer these lessons were recorded on had no IPv6 at all, and a few transcripts show it:
lesson 2 section 03 catches a program asking for an IPv6 socket and being refused. Your virtual
machine has IPv6, so **switch it off for the whole machine**, with a line for the boot loader and
a restart:

```sh
sudo mkdir -p /etc/default/grub.d
echo 'GRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT ipv6.disable=1"' | sudo tee /etc/default/grub.d/99-netlab.cfg
sudo update-grub
sudo reboot
```

The restart closes your shell; open it again with `multipass shell netlab`. Then check:

```
ubuntu@netlab:~$ ls /proc/sys/net/ipv6
ls: cannot access '/proc/sys/net/ipv6': No such file or directory
```

That error is the answer you want: the kernel has no IPv6 to configure. If `ls` lists files
instead, the setting did not reach the boot loader, and the failures section says what to try.
This is a choice to make the lab match the recordings. Nothing in the course needs IPv6 to be
missing; lesson 2 section 08 covers what IPv6 does.

## The packages

Every program the lab runs comes from Ubuntu's own archive:

```sh
echo 'postfix postfix/main_mailer_type select No configuration' | sudo debconf-set-selections
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iproute2 bind9 bind9-dnsutils unbound \
    nginx openssl tcpdump traceroute mtr-tiny netcat-openbsd curl openssh-server nftables vsftpd \
    tnftp rsync postfix dovecot-imapd dovecot-pop3d opendkim opendkim-tools opendmarc swaks \
    iputils-ping iputils-tracepath net-tools strace python3
sudo systemctl disable --now named unbound nginx vsftpd postfix dovecot opendkim opendmarc
```

The first line answers in advance the one question the mail server would ask while it installs.
**The last line stops the copies Ubuntu starts by itself.** The lab starts its own, one per
machine, each with its own configuration; the system-wide copies would only use memory and
confuse a later `ss`. The SSH server stays on, because Multipass reaches the machine through it.
That last line was not run for this course either: the computer it was recorded on had no systemd
to stop anything.

The next section puts the first of the four files in place.
