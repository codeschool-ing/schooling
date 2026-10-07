---
title: Installing it on each system
version: 1
---

**Installing Docker Desktop is the same three steps on every system: meet the requirements, run
Docker's installer, start the application once.** What differs is the requirement that fails. This
section names the steps and the failures; it has no transcripts, because the course's lab is a
Linux server and Desktop is a desktop application, and **none of the steps below was run for this
course**. The screens change between releases, so the steps are written as what has to be true,
not as which button to press.

## Windows

1. **Hardware virtualisation has to be on.** It is a firmware (BIOS or UEFI) setting, usually
   called Intel VT-x or AMD-V, and some laptops ship with it off. Task Manager's Performance tab
   shows whether it is enabled.
2. **WSL 2 has to be installed.** In an administrator PowerShell, `wsl --install` sets it up; the
   machine asks for a restart.
3. Run the installer from Docker's site and keep the option to use WSL 2. Sign out and back in if it
   asks.
4. Start Docker Desktop, and wait until its window says the engine is running.

The usual failures are the first two: an error saying virtualisation is not available, or one
saying WSL needs updating, which `wsl --update` settles.

## macOS

1. **Pick the right installer**: there is one for Apple silicon and one for Intel. The Apple menu's
   "About This Mac" says which chip the machine has.
2. Open the downloaded disk image and drag Docker into Applications.
3. Start it from Applications. The first start asks for your password, to install the parts that
   need administrator rights.

The usual failure is the wrong installer, which refuses to start, and after that, a company laptop
whose management software blocks that step.

## Linux

Docker Desktop for Linux is installed from a package Docker publishes for each supported
distribution, and needs KVM, the kernel's virtualisation, which `ls /dev/kvm` shows is available.
**For most Linux users, Docker Engine on its own is the better choice**, and lesson 6 is about it.
Install one or the other; both on one machine means two separate sets of containers, and
`docker context` deciding which one each command reaches.

## After any of them: the VM's size

Docker Desktop's settings decide how many processors, how much memory and how much disk the VM
gets. **Containers can never use more than the VM has**, whatever the laptop has: a VM given 2 GB
cannot run a database that needs 4, however much memory is free outside it. If containers are
killed for no reason you can see, lesson 4's exit code 137 is the first thing to check, and the
VM's memory setting is the second. The next section shows how to read what the VM was given.
