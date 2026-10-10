---
title: Your lab, and three ways to have one
version: 1
---

**Every lesson of this course runs something on a machine of your own**: a box office under load,
a database with a replica, five different databases one after another, a tracing system, a load
testing tool. Nothing is hosted for you. This section says what that machine needs and gives three
ways to have it; the next one builds the project every lesson measures, and the one after it says
what to do when the setup goes wrong.

The lab is **one Linux computer with Docker on it**. Every database and server in the course runs
in a container, so the list of things to install is short:

- **Docker Engine and its Compose plugin**, which run every database, the box office and the
  tools of lessons 7, 8 and 12;
- **Python 3**, for the load generator you write in section 04 and the small programs of lessons
  3, 10 and 11. Ubuntu already has it;
- **curl**, to talk to the box office by hand. Ubuntu already has it too.

What it needs from the computer underneath is the part to plan for:

| | minimum | recommended | why |
|---|---|---|---|
| processors | 2 | **4** | sections 07 and 08 give the box office 1, 2 and 4 processors, and the load generator needs some of its own |
| memory | 6 GB | **8 GB** | lesson 5 runs Cassandra and Neo4j, which want 1 to 2 GB each, one at a time |
| disk | 25 GB | **40 GB** | the course's images add up to about 6 GB, and the databases write data of their own |

With two processors every lesson still works, and sections 07 and 08 show less, because there is
less to give. The lessons say where that changes a number.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04, apart from your own system | the memory and processors you give it, while it runs; 40 GB of disk | match as printed |
| **installed** | Docker on the computer you already use | Docker's own footprint, and ports and processors shared with everything else you run | close; different on macOS and Windows where noted |
| **online** | a Linux machine in your browser | nothing on your computer; hours from a monthly allowance | close, not exact |

**The virtual machine is the recommended path**, for three reasons that matter in this course in
particular. Measurements are the whole subject, and a virtual machine has a fixed number of
processors that nothing else on your computer is using; a laptop with a browser and a video call
open measures the browser and the call as well. Lesson 5 starts databases that each want a
gigabyte or two, and they are easier to forget about in a machine you can switch off. And a
snapshot taken once the setup works gives you a clean start whenever an experiment leaves a mess.

Use the hypervisor your computer already suits: VirtualBox on Windows or Linux, UTM on an
Apple-silicon Mac, Hyper-V on Windows if it is switched on, with an Ubuntu Server 24.04 image from
ubuntu.com. `virtualization` lesson 4 builds one in VirtualBox step by step. Give it the processors
and memory of the table above, and call the machine `lab`; the transcripts' prompt reads
`ana@lab`, and yours will carry your own user name.

**Installed** means Docker on the computer you use every day. On Linux that is Docker Engine, the
same as in the virtual machine. On Windows and macOS it is Docker Desktop, which runs a small Linux
virtual machine of its own behind the scenes; it is free for personal use and for small companies
on Docker's terms, which Docker sets and can change. Everything in the course works there, with
two differences worth knowing: the processors Docker can use are set in Docker Desktop's settings,
not by the computer, and `localhost` from a container means the container itself on every system,
which the course never relies on. None of this path was run for this course.

**Online**, GitHub Codespaces gives you a Linux machine with Docker already on it and a terminal in
the browser. It costs your computer nothing; GitHub gives personal accounts a monthly allowance of
hours and charges past it, on terms it sets and can change. The size of the machine is chosen when
it is created, and lesson 5 wants the memory of the table above. It was not run for this course.

## Building it

In the virtual machine, or on Ubuntu, everything below is typed in a terminal.

**If you took `docker`**, its lesson 6 installed Docker Engine from Docker's own repository, and
that is exactly what this course needs; skip to the check at the end of this section. That is also
how the machine the transcripts were recorded on was set up.

Otherwise, the shortest way is Ubuntu's own packages:

```sh
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2 python3 curl
```

Ubuntu's Docker is a little older than Docker's own and does the same things for this course. It
was not run for this course; if any command here behaves differently, `docker` lesson 6 has the
other way, step by step.

Then let your user talk to Docker without `sudo`, by joining the group that owns Docker's socket:

```sh
sudo usermod -aG docker $USER
```

A group is read when you log in, so **log out and log in again**, or close the terminal and reopen
the connection to the virtual machine. Being in the `docker` group is as good as being root on that
machine, which is one more reason to do this in a virtual machine rather than on your own computer.

## The check

Three commands, and three answers:

```
ana@lab:~/tickets$ docker --version
Docker version 29.8.2, build 7fc2dff
ana@lab:~/tickets$ docker compose version
Docker Compose version v5.6.0
ana@lab:~/tickets$ python3 --version
Python 3.13.16
```

Your Docker version may be older or newer; anything from 25 on behaves the same here. The Python
that printed `3.13.16` above is the recording machine's own; Ubuntu 24.04 prints `3.12.3`, and the
course's programs run on any Python from 3.10 on.
