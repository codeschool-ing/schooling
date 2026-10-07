---
title: A database of your own, and three ways to have one
version: 1
---

This course is learnt by typing. Every lesson shows a query and what came back, and the point of
showing what came back is that you run the same query and compare. So before the model, a
database server on your own computer. **The platform does not run one for you**, and nothing in
this course needs anything you do not install yourself.

The engine is **PostgreSQL 16**, and `psql` is the program you type into. Every transcript in the
course was recorded with them. PostgreSQL is free, it runs on every system you are likely to own,
and it is the strictest of the common engines about what it accepts, which is what you want while
you are learning what the rules are. Lesson 12 compares it with MySQL, MariaDB and SQLite.

There are three ways to have it. One is recommended, and the other two are real options with a
cost the first does not have.

## In a virtual machine — the recommended path

A **virtual machine** is a whole computer simulated inside yours, with its own operating system,
that you can break and throw away without touching anything else. Run **Ubuntu Server 24.04 LTS**
in one, install PostgreSQL from Ubuntu's own packages, and you have the exact system this course
was recorded on: what you see should match the transcripts in everything but version numbers,
timings and the name in the prompt.

The program that runs the machine is a **hypervisor**, and which one depends on your computer:

| your computer | hypervisor | cost |
|---|---|---|
| Windows, Linux, or a Mac with an Intel processor | VirtualBox, from virtualbox.org | free |
| a Mac with Apple silicon (M1 and later) | UTM, from mac.getutm.app | free |

The steps, once:

1. Install the hypervisor, and download the Ubuntu Server 24.04 LTS installer image from
   ubuntu.com. On Apple silicon take the ARM build; everywhere else take the one marked `amd64`.
2. Create a new machine from that image with **2 processors, 2 GB of memory and a 20 GB disk**.
3. Start it and accept the installer's defaults. It asks for your name, a name for the server and
   a username — pick ones you will remember, because you will type the username every day.
4. When it reboots, log in with that username and password. You are at a prompt like
   `ana@vm:~$`, and the next section starts from there.

**What it costs your computer:** the 2 GB of memory while the machine runs, and the disk it grows
into — a few gigabytes for Ubuntu, plus LARGESHOP once lesson 9 loads its large shop. The first
setup takes a while, and most of it is waiting for the installer.

> **Your prompt will not say `ana@vm`.** In this course `ana` is the user and `vm` is the machine;
> in yours they are the names you chose in step 3. Every command is the same.

## Installed directly on your computer

If your computer **already runs Ubuntu or Debian**, skip the virtual machine: the next section's
commands work on it exactly as printed. This is the cheapest path there is.

On **macOS**, Postgres.app (postgresapp.com) and Homebrew (`brew install postgresql@16`) both
install PostgreSQL 16. On **Windows**, the installer linked from postgresql.org does. All three
cost a few hundred megabytes and a server running in the background. What they do not give you
is the same setup steps: each of them creates the first user its own way — the Windows one asks
you for a password for a user called `postgres`, and you connect with `psql -U postgres` — so
the next two sections will not match what you see. Everything from the end of this lesson on,
which is SQL, will.

## Online, on somebody else's server

Hosted PostgreSQL services give you a database and an address to connect to, and several have a
free tier — Neon and Supabase are two at the time of writing. **It costs your computer nothing**,
and it needs an account and a connection.

Use it to start if the other two are out of reach today, and plan to move. A free tier is a
company's offer, and offers change their limits and their terms; the large shop in lesson 9 may
not fit inside one; and lesson 10 needs server settings that only the owner of a server can
change. No lesson in this course depends on any provider.

## Which to pick

The virtual machine, unless your computer already runs Ubuntu. It costs an afternoon once, and it buys
the one property the others do not have: **when your screen and the transcript disagree, the
difference is in what you typed**, not in which system you are on.
