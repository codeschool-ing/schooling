---
title: Your lab, and where it runs
version: 1
---

Everything in this course is done on **your own computer**. Nobody hands you a machine to practise on:
the course's lab is something you build, and building it is the first thing the course teaches. The
next three sections set it up, the rest of this lesson makes the first guest by hand, and section 11 is
for when something goes wrong, because something usually does.

The lab is a Linux computer running **Ubuntu 24.04 LTS**, with **QEMU** and **libvirt** installed on it,
and its guests are Ubuntu as well. There are three ways to have that computer.

**Installed: Ubuntu on the computer itself. This is the one to choose if you can.** The operating
systems course installed Ubuntu, alone or beside Windows, and that installation is all this needs. The
guests then run on the real processor at nearly full speed, through KVM, which lesson 2 explains. What
it costs: about 10 GB of disk for the lab on top of the system, and memory for each guest you run at
the same time, 1 GiB each in most lessons and three at once in lesson 14. A computer with 8 GB of memory
is comfortable; 4 GB works with one guest at a time.

**In a virtual machine: Ubuntu Server 24.04 as a guest of the system you already have.** On Windows the
hypervisor is Hyper-V, which comes with Windows Pro, or VirtualBox. On a Mac with an Intel processor it
is VirtualBox or VMware Fusion, and on a Mac with an Apple processor, UTM. Your lab's guests are then guests inside a guest,
and they are only fast if the outer hypervisor passes the processor's virtualisation features on, which
is called **nested virtualisation**. In VirtualBox it is *Enable Nested VT-x/AMD-V* under the machine's
processor settings, and in Hyper-V it is `Set-VMProcessor -VMName NAME -ExposeVirtualizationExtensions
$true` in PowerShell, with the machine switched off. Without it everything still works, more slowly, and
this course was recorded exactly like that. What it costs: the outer machine needs 4 GB of memory and
40 GB of disk of its own, taken from your computer while it runs. On a Mac with an Apple processor the
guests are ARM: the commands are the same, with `arm64` where this course says `amd64`, and some numbers
in the captures will differ.

**Online: a Linux server rented by the hour.** Any provider that sells a virtual server with Ubuntu
24.04 will do, and you reach it with ssh. Most of them do not offer nested virtualisation, so the lab
runs slowly, as in the second path. What it costs: money for every hour the server exists, so destroy it
when you finish and make it again next time. Free tiers come and go and usually give too little memory
for a lab, so do not plan a course around one.

If you only want to see the windows, **VirtualBox on its own** runs on Windows, macOS and Linux, and
lesson 4 uses it. It is not enough for the rest of the course, which types its commands on a Linux host.

Where this course says `ana@host`, the person is ana and her computer is called host. Yours will have
your own names in the prompt, and the addresses and sizes in your output will differ a little from the
ones here; the commands do not.
