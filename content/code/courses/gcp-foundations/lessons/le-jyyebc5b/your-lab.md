---
title: Your lab, on your own computer
version: 1
---

**Every command in this course is one you type on your own computer.** The platform runs nothing for
you: no machine, no shell in the browser, no Google account on loan. What you need is small, and none
of it costs money or asks for a card:

- **the Google Cloud CLI**, version 589.0.0, with two of its components: the Pub/Sub emulator and the
  `beta` commands that start it;
- **Terraform** 1.16.4, which downloads Google's provider the first time a lesson asks for it;
- Python 3 with two libraries in a directory of their own, Java for the emulator, and `curl`, `jq`
  and `unzip`, which Ubuntu provides.

The lessons were recorded on **Ubuntu 24.04**, and there are three ways to have a terminal on it.

| | what it is | what it costs your computer |
|---|---|---|
| **installed** (recommended) | the tools in your own system: Ubuntu 24.04 itself, or Ubuntu 24.04 under WSL on Windows | about 1.3 GB of disk, and around 180 MB of memory while the emulator runs |
| a virtual machine | Ubuntu Server 24.04 in a hypervisor, on any system | 2 processors, 4 GB of memory and 15 GB of disk while it runs |
| online | a Linux shell rented in a browser | nothing on your computer; an account with somebody, and a limit on how long it lasts |

The disk and memory figures in the first row are measured: the last block of the next section prints
them. The second row is what Ubuntu Server asks for plus the first row, with room to spare.

**Install it, unless you are on a Mac.** On Linux it is the terminal you already have. On Windows,
WSL runs a real Ubuntu beside Windows: `wsl --install -d Ubuntu-24.04` in an administrator
PowerShell installs it, and the Ubuntu entry in the Start menu opens its terminal. Nothing this
course installs is a service or changes your system's settings. Apart from six packages from
Ubuntu's archive, it all lives in `~/gcp` and `~/.local`, and deleting them undoes it.

**A virtual machine** is the path on a Mac, and on any computer you would rather not touch. The CLI,
Terraform and the emulator all run on macOS, but the transcripts were recorded on Ubuntu, and the
system's own messages would not match. Install Ubuntu Server 24.04 in the hypervisor your system
offers: Hyper-V or VirtualBox on Windows, UTM on a Mac with Apple silicon, GNOME Boxes or
virt-manager on Linux. Canonical's Multipass does the same with one command on all three:
`multipass launch 24.04 --name gcp --cpus 2 --memory 4G --disk 15G`, then `multipass shell gcp`.
**Those two commands were not run for this course**, because the machine it was recorded on cannot
run a hypervisor; everything after them was.

**Online** is a shell somebody else's computer runs for you, such as GitHub Codespaces, or any small
Linux machine rented by the hour. It works, because the course needs nothing more than a shell that
can reach the internet, to download the tools. **No lesson depends on one company's free
allowance**, though, and each has its own hours and terms, which change. Google's own Cloud Shell is
a shell in the browser with `gcloud` already installed, and lesson 23 is about it. It does not fit
this course as the lab: it needs a Google account, and the point is that you never need one.

## Two terminals

The lab is two programs that talk to each other, so it needs **two terminal windows** side by side,
or two tabs of one:

- the first runs **the Pub/Sub emulator**, and shows what it says as it starts and stops;
- the second is where you type `gcloud`, `terraform` and `python3`, and where every transcript in
  these lessons was taken.

The emulator keeps what it is told **in memory, and forgets all of it when it stops**. That is a
feature: a lesson starts from an empty Pub/Sub by stopping the emulator and starting it again, and a
mistake costs nothing to throw away. Terraform is different. It writes what it did into a file
beside your configuration, and the lessons that use it say which directory to work in, so one
lesson's files never meet another's.

Whichever path you take, the next section starts at the same place: a terminal on Ubuntu 24.04,
logged in as yourself. The section after it, on failures, is the one to read when a command does not
answer the way the transcript does.
