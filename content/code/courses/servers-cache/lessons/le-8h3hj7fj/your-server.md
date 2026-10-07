---
title: Your server, built by you
version: 1
---

Nothing in this course runs on a machine we host. **You build the server yourself, and every command
in every lesson is typed there.** It is one Ubuntu 24.04 machine with the web servers, the caches and
a small bookshop installed on it. You can throw it away and build it again in about half an hour,
which is the property that matters most: a lesson that breaks something is a lesson you can repeat.

There are three ways to get that machine. Pick the virtual machine unless you have a reason not to.

| | what it is | what it costs |
|---|---|---|
| installed | Ubuntu 24.04 on a computer of its own, or as the system of the one you use | nothing to buy, and three web servers, two caches and a test certificate authority installed on that computer for good |
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu VM with one command, on Windows, macOS and Linux | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| online | a small virtual machine you rent by the hour from a cloud provider | money, and a machine on the internet from its first minute |

**Installed** is right if you have a spare computer you can wipe. On the computer you use every day it
is the wrong choice: everything this course installs is a server that starts at boot, and putting it
back the way it was is harder than deleting a virtual machine. Any other hypervisor works in place
of Multipass too, VirtualBox, UTM on an Apple-silicon Mac, Hyper-V or GNOME Boxes, at the price of half
an hour of installer screens. **Online** is named so that you know it exists, not recommended. A web
server on a public address is found by scanners within minutes, and this course does not harden one
until lesson 4; if you choose it anyway, read lesson 4 first. A Linux container such as WSL2 or a
Docker container is also possible, but the lessons lean on `systemctl` and on services that start at
boot, which a plain container does not have.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name web --cpus 2 --memory 2G --disk 10G
multipass shell web
```

**Those two commands were not run for this course**, because the computer it was recorded on cannot
run a hypervisor. The first creates the virtual machine and the second opens a shell inside it, as
the user `ubuntu`. Everything after this point happens in that shell.

## The packages

Every program the course uses comes from Ubuntu's own archive, so one `apt-get` installs all of them:
Nginx, Apache and Caddy, Redis and Memcached, Varnish, certbot with **Pebble**, a test certificate
authority that lesson 3 uses, and the tools and Python libraries around them.

```sh
sudo apt-get update
sudo apt-get install -y --no-install-recommends nginx apache2 caddy redis-server redis-tools \
    memcached libmemcached-tools varnish apache2-utils certbot python3-certbot-nginx pebble \
    python3-redis python3-pymemcache
sudo systemctl disable --now nginx apache2 caddy redis-server memcached varnish varnishncsa
printf '127.0.0.1\tipelivros.example www.ipelivros.example static.ipelivros.example\n' | sudo tee -a /etc/hosts
```

**The third command stops every server it just installed.** Ubuntu starts each one the moment it is
installed, and three of them cannot all have port 80; this lesson starts them one at a time, and each
later lesson starts the one it needs. The section on Apache shows what happens when two try.

The last command adds three names to `/etc/hosts`, all under `.example`, a top-level domain reserved
so that it never exists on the internet. They point at the machine itself, so
`http://ipelivros.example/` typed inside it reaches its own web server. From your computer's browser
it does not resolve, and it does not need to: every lesson works from the machine's own shell with
`curl`.

The next section puts the bookshop on the machine.
