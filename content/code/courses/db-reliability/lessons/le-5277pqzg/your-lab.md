---
title: Your lab, and three ways to have one
version: 1
---

This course is learnt by destroying databases, and **the platform does not give you one to
destroy**. Everything you type in it runs on a machine you own, built in this lesson and grown in
later ones. That is not a gap in the course. Building the environment is the first thing this job
asks for, and a server you set up yourself is the only kind you are allowed to kill.

What you need is **one Ubuntu 24.04 computer with several PostgreSQL servers on it**. Ubuntu's
packaging lets one machine run many independent servers, each with its own port, its own data
directory and its own log, and that is how every transcript in the course was recorded: a primary
on port 5432, a second server on 5433 when lesson 2 needs somewhere to restore to, and three more
that Patroni runs from lesson 16. Later lessons install the tools they need, pgBackRest in lesson 5
and Patroni, etcd, HAProxy and PgBouncer when their turn comes, each with the command that does it.

## What one machine cannot show

Several servers on one computer share a disk, a clock and a network card, so a few failures cannot
happen to one of them without happening to all. A disk dying under one server, or a cable cut
between two buildings, are things this lab **simulates** by stopping a process or blocking a port,
and the lessons that do it say so. Everything else (a crash, a corrupted file, a deleted table, a
replica that falls behind, two servers that both believe they are in charge) is real here.

## In a virtual machine: the recommended path

A **virtual machine** is a whole computer simulated inside yours, with its own operating system,
which you can break and throw away without touching anything else. For this course that matters
more than it ever has: you will delete data directories, kill servers mid-write and fill a disk
with write-ahead log, and none of that should happen on the computer you work on.

The program that runs the machine is a **hypervisor**:

| your computer | hypervisor | cost |
|---|---|---|
| Windows, Linux, or a Mac with an Intel processor | VirtualBox, from virtualbox.org | free |
| a Mac with Apple silicon (M1 and later) | UTM, from mac.getutm.app | free |

1. Install the hypervisor and download the **Ubuntu Server 24.04 LTS** installer image from
   ubuntu.com. On Apple silicon take the ARM build; everywhere else take the one marked `amd64`.
2. Create a machine from it with **2 processors, 4 GB of memory and a 25 GB disk**.
3. Start it and accept the installer's defaults. It asks for your name, a name for the server and a
   username; pick ones you will remember.
4. When it reboots, log in. You are at a prompt like `ana@vm:~$`, and the next section starts there.

**What it costs your computer:** 4 GB of memory while the machine runs, and up to 25 GB of disk,
most of it unused until lesson 2 builds a large database to time a restore against. If your
computer has 8 GB in total, close what you can while the machine is running; with less than that,
take one of the other two paths.

> **Your prompt will not say `ana@vm`.** In this course `ana` is the user and `vm` is the machine;
> in yours they are the names you chose in step 3. Every command is the same.

A hypervisor can also **snapshot** the whole machine: save its exact state and come back to it in
a second. Take one at the end of this lesson. It is the cheapest insurance this course offers, and
it is a backup of the kind lesson 3 explains, so you will know by then what it does and does not
protect.

## Installed directly on your computer

If your computer **already runs Ubuntu 24.04 or Debian 12**, the commands in this course work on it
as printed and you need no virtual machine. On **Windows**, WSL 2 runs Ubuntu 24.04 inside Windows
(`wsl --install -d Ubuntu-24.04` from an administrator's PowerShell) and gives you the same
packages; the course was not recorded there, so expect small differences in how services start.

Either way, everything you destroy is on the computer you use for everything else. That is the
real cost of this path, and why it is not the recommended one.

On **macOS** there is no installed path: Postgres.app and Homebrew both install PostgreSQL, but
neither has Ubuntu's tools for running several servers, and most commands in this course would
not exist. Use UTM.

## Online, on somebody else's computer

Any cloud provider will rent you a small **Ubuntu 24.04 virtual machine**, and you connect to it
with `ssh` and type exactly what this course shows. It costs your computer nothing and it costs
money by the hour. Pick 2 processors and 4 GB, **delete it when you finish a session**, and
recreate it from a snapshot next time. Never open its PostgreSQL ports to the internet; you
reach them from inside the machine, as the course does.

Some providers offer a few months of a small machine for free. Use one if it is there, and do not
build your plans on it: free offers change their terms, and nothing in this course depends on any
company's.

A **managed PostgreSQL service** is not a fourth path. It gives you a database and keeps the
server, its files and its replication to itself, which is exactly what this course is about.
Lesson 21 is about what such a service promises, and it is the one lesson you could take there.

## Which to pick

The virtual machine. It costs an afternoon once, it is the only path where breaking things costs
nothing, and when your screen and a transcript disagree it means the difference is in what you
typed rather than in which system you are on.
