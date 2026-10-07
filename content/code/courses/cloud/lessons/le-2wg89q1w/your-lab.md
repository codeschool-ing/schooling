---
title: Your lab, on your own computer
version: 1
---

This course needs no cloud account, but it does need a terminal. **Every command in the lessons is
one you type on your own computer**, and the platform runs nothing for you: no machine, no shell in
the browser, no sandbox. What you need is small: Python 3, two everyday tools in `curl` and `jq`,
and the AWS command line, which never gets a key. Lessons 4 and 5 add two Python programs, **moto**
and **cloud-init**, to imitate a service and check a file on your own machine. The next two sections install all of it and give you the one program
the course is built on, the price sheet. None of it costs money, and none of it needs a card.

The lessons were recorded on Ubuntu 24.04, and there are three ways to have a terminal on it.

| | what it is | what it costs your computer |
|---|---|---|
| **installed** (recommended) | the tools in your own system: Ubuntu 24.04 itself, or Ubuntu 24.04 under WSL on Windows | about 1.3 GB of disk, nothing running in the background, and 4 GB of free memory while the price sheet reads its largest file |
| a virtual machine | Ubuntu Server 24.04 in a hypervisor, on any system | 2 processors, 4 GB of memory and 15 GB of disk while it runs |
| online | a Linux shell rented in a browser | nothing on your computer; an account with somebody, and a limit on how long it lasts |

**Install it, unless you are on a Mac.** On Linux it is the terminal you already have. On Windows,
WSL runs a real Ubuntu beside Windows: `wsl --install -d Ubuntu-24.04` in an administrator
PowerShell installs it, and the Ubuntu entry in the Start menu opens its terminal. Nothing this
course installs needs to be a service or to change your system's settings: apart from five packages
from Ubuntu's archive, it all lives in two directories in your home, and deleting them undoes it.

**A virtual machine** is the path on a Mac, and on any computer you would rather not touch. The
tools themselves run on macOS too, but the transcripts were recorded on Ubuntu, and a few of them,
the system's own messages above all, would not match. Install Ubuntu Server 24.04 from its image in
the hypervisor your system offers: Hyper-V or VirtualBox on Windows, UTM on a Mac with Apple
silicon, GNOME Boxes or virt-manager on Linux. Canonical's Multipass does the same with one command
on all three: `multipass launch 24.04 --name cloud --cpus 2 --memory 4G --disk 15G`, then
`multipass shell cloud`. **Those two commands were not run for this course**, because the machine
it was recorded on cannot run a hypervisor; everything after them was.

**Online** is a shell somebody else's computer runs for you, such as GitHub Codespaces, or any
small Linux machine rented by the hour. It works, because nothing here needs more than a shell with
the network. **No lesson depends on one company's free allowance**, though, and each has its own
hours and terms, which change. AWS's own CloudShell is the one that does not fit: it needs an AWS
account, and the point of this course is that you never need one.

Whichever you pick, the next section starts at the same place: a terminal on Ubuntu 24.04, logged
in as yourself. The section after it, on failures, is the one to read when a command does not
answer the way the transcript does.
