---
title: Your server, built by you
version: 1
---

Nothing in this course runs on a machine we host. **You build the server yourself, on your own
computer, and every command in every lesson is typed there.** It is one Ubuntu 24.04 machine with
the web servers, the caches and a small bookshop installed on it. You can throw it away and
build it again in about ten minutes, which is the property that matters most: a lesson that breaks
something is a lesson you can repeat.

There are three ways to get that machine. Pick the first unless you have a reason not to.

| | what it is | what it costs your computer |
|---|---|---|
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu VM with one command, on Windows, macOS and Linux | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| a virtual machine in any hypervisor | VirtualBox, UTM on an Apple-silicon Mac, Hyper-V or GNOME Boxes, installing the Ubuntu Server 24.04 image yourself | the same, plus half an hour of installer screens |
| a small cloud server | a virtual machine you rent by the hour from a provider | money, and a machine on the internet from its first minute |

The cloud option is named so that you know it exists, not recommended. A web server on a public
address is found by scanners within minutes, and this course does not harden one until lesson 4.
If you choose it anyway, read lesson 4 first. A Linux container such as WSL2 or a Docker container
is also possible, but the lessons lean on `systemctl` and on services that start at boot, which a
plain container does not have.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```
multipass launch 24.04 --name web --cpus 2 --memory 2G --disk 10G
multipass shell web
```

**Those two commands were not run for this course**, because the computer it was recorded on cannot
run a hypervisor. The first creates the virtual machine and the second opens a shell inside it, as
the user `ubuntu`. Everything after this point happens in that shell.

## Inside the machine

The course's files and packages are installed by one script, `lab.sh`, published with the course's
source. Copy it into the machine (`multipass transfer lab.sh web:` does that, and was not run here either) and run:

```
sudo bash lab.sh install
```

It does what you would otherwise type by hand. It runs `apt-get install` for every package the
course uses, all of them from Ubuntu's own archive: Nginx, Apache, Caddy, Redis, Memcached,
Varnish, certbot and the small tools around them. It writes the bookshop, `/opt/shop/shop.py`, and
starts two copies of it. It writes the shop's static front into `/var/www/ipe`, adds three names to
`/etc/hosts` and puts a Python module in `~/work` for lessons 8 to 11. Read it before you run it;
it is short, and running a script as root that you have not read is a habit worth not having.

The transcripts in this course were recorded on a machine called `web`, as a user called `ana`.
Yours says `ubuntu@web` if you used Multipass, and that is the only difference you should see:

```
ana@web:~$ grep PRETTY /etc/os-release; nproc; free -h | head -2
PRETTY_NAME="Ubuntu 24.04 LTS"
4
               total        used        free      shared  buff/cache   available
Mem:            15Gi       646Mi        12Gi        13Mi       2.7Gi        15Gi
ana@web:~$ apt-cache policy nginx apache2 caddy | grep -E '^[a-z]|Installed'
nginx:
  Installed: 1.24.0-2ubuntu7.18
apache2:
  Installed: 2.4.58-1ubuntu8.15
caddy:
  Installed: 2.6.2-6ubuntu0.24.04.3
ana@web:~$ systemctl is-active shop@1 shop@2 nginx apache2 caddy
active
active
inactive
inactive
inactive
ana@web:~$ grep ipelivros /etc/hosts
127.0.0.1	ipelivros.example www.ipelivros.example static.ipelivros.example
ana@web:~$ ls -l ~/work
total 4
-rw-r--r-- 1 ana ana 885 Sep  1 10:00 catalogue.py
```

The memory and the processor count are the recording machine's; yours reports what you gave the
virtual machine. What should match is the rest. **The two copies of the shop are running and every
web server is stopped**, because Ubuntu starts each server the moment it is installed and three of
them cannot all have port 80. The script stops them so that this lesson can start them one at a time,
and the section on Apache shows what happens when two try.

The three names in `/etc/hosts` are under `.example`, a top-level domain reserved so that it never
exists on the internet. They point at the machine itself, so `http://ipelivros.example/` typed
inside it reaches its own web server. From your computer's browser it does not resolve, and
it does not need to: every lesson works from the machine's own shell with `curl`.

**What the recording machine did differently**, so that nothing surprises you. It was a container
booted with its own systemd rather than a virtual machine, which behaves the same for everything
this course does. It had no IPv6, so the one line in Nginx's default site that listens on `[::]:80`
was removed; yours keeps it. And `ana` could use `sudo` without typing a password, which keeps the
transcripts free of password prompts.
