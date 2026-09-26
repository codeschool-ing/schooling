---
title: Hyper-V
version: 1
---

**Hyper-V** is Microsoft's hypervisor, and it is already on most business computers: it comes with
Windows 10 and 11 **Pro, Enterprise and Education**, not Home, and with Windows Server. It is switched
on as a Windows feature, and after a reboot the computer starts Microsoft's hypervisor first, with
Windows running on top of it, lesson 2's type 1 on a laptop.

It is managed with **Hyper-V Manager**, a window that lists machines and their state, and with
PowerShell. Four of its choices differ from the other hypervisors in this course, and all four come up
in support calls:

- **Generation 1 or 2**, chosen when the machine is made and never changed. Generation 1 imitates an old
  PC with a BIOS; generation 2 has UEFI and Secure Boot and is the right choice for any modern system.
  A **Linux guest on generation 2 will not boot until Secure Boot is switched to the template called
  *Microsoft UEFI Certificate Authority***, which is the one most often missed.
- **VHDX** is its disk format, and **checkpoint** is its word for snapshot. A *production* checkpoint,
  the default, asks the guest to put its files in order and saves no memory; a *standard* one saves
  the running state, like the snapshots of lesson 9.
- **Integration Services** are its guest agent. Windows guests have them built in, and Linux has them in
  its kernel.
- **Enhanced session** connects to a Windows guest the way Remote Desktop does, with clipboard, sound and
  a screen that resizes.
