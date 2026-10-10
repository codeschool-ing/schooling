---
title: A slow database of your own, and three ways to have one
version: 1
---

This course is learnt by measuring. Every lesson runs a query, times it, reads what the server
did, changes one thing and times it again, and the point of showing those numbers is that you
produce your own and compare. So before the first suspect, a database server on your own
computer. **The platform does not run one for you**, and nothing in this course needs anything
you do not install yourself.

The engine is **PostgreSQL 16**, from Ubuntu's own packages, and `psql` is the program you type
into. If you took `db-administration`, you already have a server like this one, and the next
section only adds a database to it. Every transcript in the course was recorded on the setup
described here.

What this course needs is not quite what other courses need. A course about SQL is satisfied by
any database that works. **This one needs a database that is slow**: big enough that a bad plan
costs seconds rather than microseconds, and on a machine whose memory you know. That rules some
options out, as the three paths below say.

## In a virtual machine — the recommended path

A **virtual machine** is a whole computer simulated inside yours, with its own operating system,
that you can break and throw away without touching anything else. That matters more here than in
most courses: you will change server settings, fill the disk on purpose, start two hundred
connections at once and kill processes, and none of it should happen on the computer you work on.

The program that runs the machine is a **hypervisor**:

| your computer | hypervisor | cost |
|---|---|---|
| Windows, Linux, or a Mac with an Intel processor | VirtualBox, from virtualbox.org | free |
| a Mac with Apple silicon (M1 and later) | UTM, from mac.getutm.app | free |

The steps, once:

1. Install the hypervisor, and download the **Ubuntu Server 24.04 LTS** installer image from
   ubuntu.com. On Apple silicon take the ARM build; everywhere else take the one marked `amd64`.
2. Create a new machine from that image with **2 processors, 4 GB of memory and a 30 GB disk**.
3. Start it and accept the installer's defaults. It asks for your name, a name for the server and
   a username. This course calls the server `vm` and the user `ana`.
4. When it reboots, log in. You are at a prompt like `ana@vm:~$`, and the next section starts
   from there.

**What it costs your computer:** 4 GB of memory while the machine runs, so the computer needs 8 GB
or more to stay comfortable, and about 10 GB of disk once the course's database is loaded and a
few lessons have made copies of it. With less memory, give the machine 2 GB: everything still
works and every query is slower, which is a lesson of its own (lesson 1 section 06 shows why).

> **Your prompt will not say `ana@vm`.** In this course `ana` is the user and `vm` is the machine;
> in yours they are the names you chose in step 3. Every command is the same.

## Installed directly on your computer

If your computer **already runs Ubuntu or Debian**, you can skip the virtual machine: every
command in this course works on it as printed. It is the cheapest path in memory, and it costs
something the virtual machine does not — the experiments in lessons 15, 16 and 23 load the
computer you are working on, and a server setting left behind stays behind.

On **macOS** (Postgres.app or `brew install postgresql@16`) and **Windows** (the installer
linked from postgresql.org) you get the same PostgreSQL 16 and the same SQL. What does not match
is everything around it: the commands that restart the server, where its configuration file
lives, how a second server is started in lesson 20 and how a connection pooler is installed in
lesson 16. Every query plan in the course will match; a third of the shell commands will not.

## Online, on somebody else's server

Hosted PostgreSQL services hand you a database and an address, and some have a free tier — Neon
and Supabase are two at the time of writing. **For this course it is the weakest path**, and it
is worth knowing why before choosing it:

- the course's database is about **1.3 GB**, which is bigger than most free tiers allow;
- half the lessons change server settings with `ALTER SYSTEM` or restart the server, and a
  hosted service lets its customers do neither;
- the machine is one of the three suspects, and on a hosted service you cannot see it.

Use it to read plans if the other two are out of reach today, with a smaller database, and plan
to move. No lesson depends on any provider, and a free tier is a company's offer that can change
its limits whenever it likes.

## Which to pick

The virtual machine, unless your computer already runs Ubuntu. It costs an afternoon once, and it
buys the property this course leans on more than any other: **when your timings and the
transcript's differ, you know the difference is the machine**, because everything else is the
same.
