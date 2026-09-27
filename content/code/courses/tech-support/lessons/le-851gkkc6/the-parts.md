---
title: The parts inside
version: 1
---

Sometimes the register needs more than one line per machine: a memory upgrade to plan, or a warranty
claim that asks for a part's details. `lshw` lists the parts:

```
ana@pc1:~$ sudo lshw -short -class disk -class network -class memory 2>/dev/null
H/W path           Device      Class          Description
=========================================================
/0/0                           memory         96KiB BIOS
/0/1000                        memory         1GiB System Memory
/0/1000/0                      memory         1GiB DIMM RAM
/0/100/1/0                     network        Virtio 1.0 network device
/0/100/1/0/0       enp1s0      network        Ethernet interface
/0/100/1.3/0/0     /dev/vda    disk           8589MB Virtual I/O device
```

One **1GiB** memory module, a **virtio** network card, and an **8589MB** disk, which is lesson 8 of the
virtualisation course seen from inside: the devices a hypervisor offers its guests. On a physical
computer the same command names the memory's slots and speed, the disk's model and serial, and the
network card's maker, which is what a vendor asks for when a part fails.

Keep the register at the level of detail somebody actually uses. A line per computer is enough for most
offices; parts are worth tracking when they are bought, moved or claimed separately, like the disks of a
server.
