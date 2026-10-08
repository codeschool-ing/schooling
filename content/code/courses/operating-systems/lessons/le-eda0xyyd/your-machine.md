---
title: A machine of your own for this course
version: 1
---

Every transcript in this course was typed on one machine: a small Ubuntu server called `server`, with
PowerShell 7 installed beside bash. **You build the same machine, on your own computer, before the next
section asks you to type anything.** Nobody hosts one for you, and that is part of the subject: putting
a system on a machine is lessons 2 to 4, and the first one you install is this one.

There are three ways to have it. **Take the virtual machine** unless you have a reason not to.

| | what it is | what it costs your computer |
|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04 LTS running in a window on the computer you already use | 2 processors and 2 GB of memory while it runs, a virtual disk of 25 GB that only takes the space it fills, and about 4 GB for the installer you download |
| installed | Ubuntu on a computer of its own, or beside Windows on yours | a spare computer, or part of your disk and a change of partitions (lesson 3) that loses data when done wrong |
| online | a small Linux server rented from a cloud provider | money by the hour or the month, a card on file, and a machine on the internet from its first minute |

**Why the virtual machine.** Lessons 9 to 17 change users, permissions, services and the files that
configure the system, and a lesson that breaks something should cost you nothing but a rebuild. A virtual
machine is a file on your disk: you can save its state before a lesson, go back to it after, and delete
it when the course is over, and the computer you study on is never touched. A computer with 8 GB of
memory runs it comfortably beside a browser. With 4 GB it runs, if you close everything else first.

The program that runs it is a *hypervisor*, and which one depends on what your computer runs:

| your computer | the hypervisor | the installer to download |
|---|---|---|
| Windows | VirtualBox, free; or Hyper-V, built into the Pro edition | Ubuntu Server, `amd64` |
| a Mac with an Intel processor | VirtualBox | Ubuntu Server, `amd64` |
| a Mac with Apple silicon (M1 and later) | UTM, free | Ubuntu Server, `arm64` |
| Linux | virt-manager, or VirtualBox | Ubuntu Server, `amd64` |

The virtualization course explains what a hypervisor does. Here it is only the window the server runs in.

**Installed** is right if you have a spare computer you can wipe. Beside Windows it is possible, and
lesson 3 shows how, but the course's later lessons break things on purpose and you would be breaking the
computer you need to read the next lesson. **Online** is named so that you know it exists. Several
providers offer a small server free for a while, and their terms change; nothing in this course depends
on one of them. A server with a public address is probed by strangers within minutes, so if you choose
it, keep the SSH key the provider gives you and never set a simple password.

## Windows and macOS

The server is where you type the Linux and PowerShell parts, which is most of what you type in this course.
The parts only Windows or macOS can show were not run for this course, each lesson says so where they
appear, and you practise them on whichever of the two you have.

- **If your computer runs Windows**, it is your Windows lab. You can also install Windows 11 into a virtual
  machine with lesson 2's installer: it needs 4 GB of memory and 64 GB of disk, and a virtual TPM, which
  VirtualBox 7 and Hyper-V both offer. Without a product key it works, with a reminder on screen and the
  personalisation settings locked.
- **If you have a Mac**, it is your macOS lab. macOS may only run on Apple's own hardware, in a virtual
  machine or not, so without a Mac lesson 4 is one to read rather than one to type.

The next section builds the server.
