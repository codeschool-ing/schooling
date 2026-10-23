---
title: Your lab, on your own computer
version: 1
---

**Every command in this course is one you type on your own computer.** The platform runs nothing for
you: no machine, no shell in the browser, no cloud account on loan. What you need is small, it is
free, and none of it asks for a card:

- **the AWS command line**, version 2, the program `aws`;
- **moto**, installed with Python's package installer into a directory of its own;
- Python 3, `curl`, `jq` and `unzip`, which Ubuntu provides.

Lessons 12 and 13 add three programs of their own, Terraform, Checkov and pip-audit, and each of
those lessons installs what it uses before its first command.

**If you took `aws-foundations`, you already have this lab.** It is the same directory, `~/aws`,
the same versions and the same settings, and you can go straight to the section after next to check
that it still answers. If you took only the `cloud` course, its moto lived in `~/cloud` and listened
on port 5000; this one is new, and the two do not disturb each other.

The lessons were recorded on **Ubuntu 24.04**, and there are three ways to have a terminal on it.

| | what it is | what it costs your computer |
|---|---|---|
| **installed** (recommended) | the tools in your own system: Ubuntu 24.04 itself, or Ubuntu 24.04 under WSL on Windows | about 600 MB of disk for lesson 1, 1 GB by lesson 13, and 80 MB of memory or more while moto runs |
| a virtual machine | Ubuntu Server 24.04 in a hypervisor, on any system | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| online | a Linux shell rented in a browser | nothing on your computer; an account with somebody, and a limit on how long it lasts |

**Install it, unless you are on a Mac.** On Linux it is the terminal you already have. On Windows,
WSL runs a real Ubuntu beside Windows: `wsl --install -d Ubuntu-24.04` in an administrator
PowerShell installs it, and the Ubuntu entry in the Start menu opens its terminal. Nothing this
course installs is a service or changes a system setting. Apart from five packages from Ubuntu's
archive, everything lives in `~/aws` and `~/.local`, and deleting the two undoes it.

**A virtual machine** is the path on a Mac, and on any computer you would rather not touch. The AWS
command line and moto both run on macOS, but the transcripts were recorded on Ubuntu, and the
system's own messages would differ. Install Ubuntu Server 24.04 in the hypervisor your system
offers: Hyper-V or VirtualBox on Windows, UTM on a Mac with Apple silicon, GNOME Boxes or
virt-manager on Linux. Canonical's Multipass does it with one command on all three:
`multipass launch 24.04 --name cloudsec --cpus 2 --memory 2G --disk 10G`, then
`multipass shell cloudsec`. **Those two commands were not run for this course**, because the
machine it was recorded on cannot run a hypervisor; everything after them was.

**Online** means a shell somebody else's computer runs for you, such as GitHub Codespaces or a
small Linux machine rented by the hour. It works, because the course needs only a shell that can
reach the internet to download the tools. **No lesson depends on one company's free allowance**,
though: each has its own hours and terms, and they change. AWS CloudShell, the shell inside the
AWS console, does not fit, since it needs the AWS account this course is built to do without.

## Two terminals

The lab is two programs talking to each other, so it wants **two terminal windows** side by side,
or two tabs of one:

- the first runs **moto**, and prints a line for every request that reaches it;
- the second is where you type `aws` commands, and where every transcript in these lessons was
  taken.

**Keep the first one in view.** It is the closest thing this lab has to an audit log, and lesson 15
returns to it for exactly that reason: every request you send shows up there, with the time and the
answer it got.

moto forgets everything when it stops. That is useful in a security course, where you will spend
whole sections making an account worse on purpose: stopping moto throws the damage away, and the
next lesson starts from an empty AWS. Each lesson says what to create before its first command.
