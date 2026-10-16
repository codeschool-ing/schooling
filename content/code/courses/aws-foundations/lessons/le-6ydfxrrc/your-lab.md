---
title: Your lab, on your own computer
version: 1
---

**Every command in this course is one you type on your own computer.** The platform runs nothing for
you: no machine, no shell in the browser, no AWS account on loan. What you need is small, and none
of it costs money or asks for a card:

- **the AWS command line**, version 2, the program `aws`. It is the real one AWS publishes, and in
  this course it never talks to AWS;
- **moto**, the imitation of AWS described in the section before this one, installed with Python's
  package installer into a directory of its own;
- Python 3, `curl`, `jq` and `unzip`, which Ubuntu provides.

The lessons were recorded on **Ubuntu 24.04**, and there are three ways to have a terminal on it.

| | what it is | what it costs your computer |
|---|---|---|
| **installed** (recommended) | the tools in your own system: Ubuntu 24.04 itself, or Ubuntu 24.04 under WSL on Windows | about 600 MB of disk, and 80 MB of memory or more while moto runs, growing with what you create in it |
| a virtual machine | Ubuntu Server 24.04 in a hypervisor, on any system | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| online | a Linux shell rented in a browser | nothing on your computer; an account with somebody, and a limit on how long it lasts |

**Install it, unless you are on a Mac.** On Linux it is the terminal you already have. On Windows,
WSL runs a real Ubuntu beside Windows: `wsl --install -d Ubuntu-24.04` in an administrator
PowerShell installs it, and the Ubuntu entry in the Start menu opens its terminal. Nothing this
course installs is a service or changes your system's settings. Apart from five packages from
Ubuntu's archive, it all lives in `~/aws`, `~/.local` and `~/.cache/aws-prices`, and deleting them undoes it.

**A virtual machine** is the path on a Mac, and on any computer you would rather not touch. The AWS
command line and moto both run on macOS, but the transcripts were recorded on Ubuntu, and the
system's own messages would not match. Install Ubuntu Server 24.04 in the hypervisor your system
offers: Hyper-V or VirtualBox on Windows, UTM on a Mac with Apple silicon, GNOME Boxes or
virt-manager on Linux. Canonical's Multipass does the same with one command on all three:
`multipass launch 24.04 --name aws --cpus 2 --memory 2G --disk 10G`, then `multipass shell aws`.
**Those two commands were not run for this course**, because the machine it was recorded on cannot
run a hypervisor; everything after them was.

**Online** is a shell somebody else's computer runs for you, such as GitHub Codespaces, or any small
Linux machine rented by the hour. It works, because the course needs nothing more than a shell that
can reach the internet once, to download the tools. **No lesson depends on one company's free
allowance**, though, and each has its own hours and terms, which change. AWS's own CloudShell, a
shell in the AWS console, does not fit this course: it needs an AWS account, and the point is that
you never need one.

## Two terminals

The lab is two programs that talk to each other, so it needs **two terminal windows** side by side,
or two tabs of one:

- the first runs **moto**, and shows a line for every request that reaches it;
- the second is where you type `aws` commands, and where every transcript in these lessons was
  taken.

moto keeps what it is told **in memory, and forgets all of it when it stops**. That is a feature: a
lesson starts from an empty AWS by stopping moto and starting it again, and a mistake costs nothing
to throw away. It also means nothing you create survives the end of a session, so each lesson says
what to create before its first command.

Whichever path you take, the next section starts at the same place: a terminal on Ubuntu 24.04,
logged in as yourself. The section after it, on failures, is the one to read when a command does not
answer the way the transcript does.
