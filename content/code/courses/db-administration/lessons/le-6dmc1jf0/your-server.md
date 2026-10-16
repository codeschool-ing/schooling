---
title: A server of your own, and three ways to have one
version: 1
---

This course is learnt on a server **you are allowed to break**. Lesson 5 edits the configuration
file, lesson 8 kills the server in the middle of a write, lesson 14 lets autovacuum fall behind
and lesson 20 upgrades the whole thing to a new major version. **The platform does not run a
server for you**, and nothing in the course needs anything you do not install yourself.

The server is **PostgreSQL 16 on Ubuntu Server 24.04 LTS**, installed from Ubuntu's own packages.
Every transcript in the course was recorded on exactly that, on a machine called `db` with a user
called `ana`. There are three ways to have it. One is recommended; the other two are real options
with a cost the first does not have.

## In a virtual machine — the recommended path

A **virtual machine** is a whole computer simulated inside yours, with its own operating system,
its own disk and its own administrator, which is you. It can be broken and thrown away without
touching anything else on your computer. That last property is the one this course needs.

The program that runs it is a **hypervisor**, and which one depends on your computer:

| your computer | hypervisor | cost |
|---|---|---|
| Windows, Linux, or a Mac with an Intel processor | VirtualBox, from virtualbox.org | free |
| a Mac with Apple silicon (M1 and later) | UTM, from mac.getutm.app | free |

The steps, once:

1. Install the hypervisor, and download the **Ubuntu Server 24.04 LTS** installer image from
   ubuntu.com. On Apple silicon take the ARM build; everywhere else take the one marked `amd64`.
2. Create a new machine from that image with **2 processors, 4 GB of memory and a 25 GB disk**.
3. Start it and accept the installer's defaults. It asks for your name, a name for the server and
   a username. Call the server `db` if you want your prompt to look like the course's; the username
   is yours to choose, and you will type it every day.
4. When the installer offers to install **OpenSSH server**, accept. It lets you connect from your
   own terminal with `ssh`, which copies and pastes far better than the hypervisor's window.
5. When it reboots, log in. You are at a prompt like `ana@db:~$`, and the section after this one
   starts from there.

**What it costs your computer:** the 4 GB of memory while the machine runs, two of your processors'
attention, and the disk it grows into: a few gigabytes for Ubuntu and PostgreSQL, and a little more
each time a later lesson makes a table large on purpose. A computer with 8 GB of memory runs it;
with less, give the machine 2 GB and expect lesson 6's arithmetic to come out smaller than the
course's.

> **Your prompt will not say `ana@db`** unless you chose those names. In this course `ana` is the
> user and `db` is the server; in yours they are the names you gave in step 3. Every command is
> the same.

## Installed directly on your computer

If your computer **already runs Ubuntu 24.04 or Debian 12**, you can skip the virtual machine:
every command in the course works on it as printed. It is the cheapest path there is, and it has
one cost the virtual machine does not: the server you break is the one on the computer you work
on. Lesson 9 fills a disk; do that on your laptop and it is your laptop's disk.

On **macOS** (Postgres.app, or Homebrew's `postgresql@16`) and on **Windows** (the installer
linked from postgresql.org) PostgreSQL itself is the same, and everything you do inside `psql` —
roles, grants, vacuum, statistics, schema changes — matches the course. What does not match is
everything around it: where the files live, how the service starts, where the log goes and who
the first user is. Lessons 3 to 5, 9 and 19 will not look like your screen.

## Online, on somebody else's server

A hosted PostgreSQL service gives you a database and an address, and several have a free tier.
**It costs your computer nothing**, and it needs an account and a connection.

It is the weakest of the three for this course specifically, and the previous section says why:
no shell, no files, no log, no superuser. You can follow lessons 11 to 17 and 22 on it and almost
nothing else. A free tier is also a company's offer, and offers change their limits and their
terms. **No lesson depends on any provider**, and if this is the only path open to you today, use
it to start and move to a virtual machine when you can.

## Which to pick

The virtual machine, unless your computer already runs Ubuntu. It costs an afternoon once, and it
buys the one property the others lack: **when your screen and the transcript disagree, the
difference is in what you typed**, not in which system you are on.
