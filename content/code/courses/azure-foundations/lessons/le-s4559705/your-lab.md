---
title: Your lab, on your own computer
version: 1
---

**Every command in this course is one you type on your own computer.** The platform runs nothing for
you: no machine, no shell in the browser, no Azure account on loan. What you need is small, and none
of it costs money or asks for a card:

- **the Azure CLI**, the program `az`, which Microsoft publishes as a Python package, installed into
  a directory of its own;
- **the Bicep CLI**, which the Azure CLI downloads for you the first time;
- **Terraform**, one program from HashiCorp, and the providers it downloads when a lesson asks;
- Python 3, `curl`, `jq`, `unzip` and `dig`, which Ubuntu provides.

The lessons were recorded on **Ubuntu 24.04**, and there are three ways to have a terminal on it.

| | what it is | what it costs your computer |
|---|---|---|
| **installed** (recommended) | the tools in your own system: Ubuntu 24.04 itself, or Ubuntu 24.04 under WSL on Windows | about 1.1 GB of disk once everything is in; nothing runs in the background |
| a virtual machine | Ubuntu Server 24.04 in a hypervisor, on any system | 2 processors, 2 GB of memory and 10 GB of disk while it runs |
| online | a Linux shell rented in a browser | nothing on your computer; an account with somebody, and a limit on how long it lasts |

**Install it, unless you are on a Mac.** On Linux it is the terminal you already have. On Windows,
WSL runs a real Ubuntu beside Windows: `wsl --install -d Ubuntu-24.04` in an administrator
PowerShell installs it, and the Ubuntu entry in the Start menu opens its terminal. Nothing this
course installs is a service or changes your system's settings. Apart from six packages from
Ubuntu's archive, it all lives in `~/azure`, `~/.local/bin` and `~/.terraform.d`, and deleting them
undoes it.

**A virtual machine** is the path on a Mac, and on any computer you would rather not touch. The Azure
CLI, Bicep and Terraform all run on macOS, but the transcripts were recorded on Ubuntu, and the
system's own messages would not match. Install Ubuntu Server 24.04 in the hypervisor your system
offers: Hyper-V or VirtualBox on Windows, UTM on a Mac with Apple silicon, GNOME Boxes or
virt-manager on Linux. Canonical's Multipass does the same with one command on all three:
`multipass launch 24.04 --name azure --cpus 2 --memory 2G --disk 10G`, then `multipass shell azure`.
**Those two commands were not run for this course**, because the machine it was recorded on cannot
run a hypervisor; everything after them was.

**Online** is a shell somebody else's computer runs for you, such as GitHub Codespaces, or any small
Linux machine rented by the hour. It works, because the course needs nothing more than a shell that
can reach the internet, to download the tools and to ask the few public services the lessons ask.
**No lesson depends on one company's free allowance**, though, and each has its own hours and
terms, which change. Azure's own Cloud Shell, a terminal in the Azure portal with `az` already in
it, does not fit this course: it needs an Azure account, and the point is that you never need one.
Lesson 24 says what it is for.

## One terminal, and nothing running

A lab that imitated a cloud would keep that imitation running in a second window. **This lab has
nothing to imitate Azure with, so it needs one terminal and nothing in the background.**
Every tool starts when you type its name and stops when it has answered.

What the lab remembers between sessions is small and lives in files: the Azure CLI's settings in
`~/azure/.azure`, Terraform's providers in `~/.terraform.d`, and whatever Bicep and Terraform files a
lesson asks you to write, each in a directory of its own under `~/azure`. Each lesson says which
directory to make before its first command, and deleting that directory starts the lesson again.

Whichever path you take, the next section starts at the same place: a terminal on Ubuntu 24.04,
logged in as yourself. The section after it, on failures, is the one to read when a command does
not answer the way the transcript does.
