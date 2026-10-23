---
title: A machine for this course, and three ways to have one
version: 1
---

This course is learnt by building. Every lesson shows a command and what came back, and the point
of showing what came back is that you run the same command and compare. So before Maven, a
machine. **The platform runs nothing for you**: the JDK, Maven, and later PostgreSQL and Docker
are installed by you, on a computer you control, and every transcript in this course was recorded
on exactly such a computer.

That computer is **Ubuntu 24.04** with **OpenJDK 25** and **Maven 3.8.7**, both from Ubuntu's own
archive. There are three ways to have one. One is recommended, and the other two are real options
with costs the first does not have.

## In a virtual machine — the recommended path

A **virtual machine** is a whole computer simulated inside yours, with its own operating system,
that you can break and throw away without touching anything else. Run **Ubuntu Server 24.04 LTS**
in one and install the tools from Ubuntu's packages, and you have the system this course was
recorded on: what you see should match the transcripts in everything but timings, a few build
numbers, and the name in the prompt.

The program that runs the machine is a **hypervisor**, and which one depends on your computer:

| your computer | hypervisor | cost |
|---|---|---|
| Windows, Linux, or a Mac with an Intel processor | VirtualBox, from virtualbox.org | free |
| a Mac with Apple silicon (M1 and later) | UTM, from mac.getutm.app | free |

The steps, once:

1. Install the hypervisor, and download the Ubuntu Server 24.04 LTS installer image from
   ubuntu.com. On Apple silicon take the ARM build; everywhere else take the one marked `amd64`.
2. Create a new machine from that image with **2 processors, 4 GB of memory and a 30 GB disk**.
   More of either makes builds and test runs quicker, and nothing in the course needs more.
3. Start it and accept the installer's defaults. It asks for your name, a name for the server and
   a username. Pick ones you will remember, because you will type the username every day.
4. When it reboots, log in with that username and password. You are at a prompt like
   `ana@vm:~$`, and the next section starts from there.

**What it costs your computer**, and why the numbers are larger than a first Java course needs.
The JDK and Maven are about 400 MB installed. The libraries Maven downloads for this course's
projects fill a few hundred megabytes more under your home directory. Lesson 9 adds PostgreSQL,
and lesson 19 adds Docker, which runs a real PostgreSQL in a container for the tests and keeps its
images on the disk. A Spring Boot application, a database and a test run side by side are what the
4 GB of memory is for.

> **Your prompt will not say `ana@vm`.** In this course `ana` is the user and `vm` is the machine;
> in yours they are the names you chose in step 3. Every command is the same.

## Installed directly on your computer

If your computer **already runs Ubuntu 24.04**, skip the virtual machine: the next section's
commands work on it exactly as printed, and this is the cheapest path there is. Another release of
Ubuntu, or Debian, may not offer the same package names, and `apt search openjdk` says which ones
it does.

On **macOS** and **Windows**, an OpenJDK 25 build and Maven are both available — Eclipse Temurin
from adoptium.net is a common JDK, Maven comes from maven.apache.org, and Homebrew installs both on
a Mac. What you get is a newer Maven than 3.8.7, and that changes some of what this lesson prints:
the section on plugins shows a build that fails because of which Maven is running, and on a newer
Maven that build may succeed. The commands from lesson 9 on, which install PostgreSQL and
Docker the Ubuntu way, will not apply as printed either.

## Online, in a cloud development environment

A **cloud development environment** is a Linux machine in somebody else's data centre that you
reach from the browser, with an editor and a terminal. GitHub Codespaces is one at the time of
writing, with a monthly free allowance. **It costs your computer nothing**, and it needs an
account and a connection.

Use it to start if the other two are out of reach today, and plan to move. The machine's operating
system and its preinstalled Java are the provider's choice, so the install commands may need
adjusting; free allowances are a company's offer, and offers change; and lesson 19 runs containers,
which an online environment allows or not at its owner's discretion. No lesson in this course
depends on any provider.

## Which to pick

The virtual machine, unless your computer already runs Ubuntu 24.04. It costs an afternoon once,
and it buys the one property the others do not have: **when your screen and the transcript
disagree, the difference is in what you typed**, not in which system you are on.
