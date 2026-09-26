---
title: How a guest can tell
version: 1
---

From inside, a guest is not meant to notice, but its hardware has a maker's name like any other, and
the maker is the hypervisor:

```
ana@vm1:~$ cat /sys/class/dmi/id/sys_vendor /sys/class/dmi/id/product_name
QEMU
Ubuntu 24.04 PC (Q35 + ICH9, 2009)
ana@vm1:~$ sudo dmesg | grep -m1 "DMI:"
[    0.000000] DMI: QEMU Ubuntu 24.04 PC (Q35 + ICH9, 2009), BIOS 1.16.3-debian-1.16.3-2 04/01/2014
```

`/sys/class/dmi/id` holds what the firmware reports about the machine: the maker is `QEMU` and the
product is `Ubuntu 24.04 PC (Q35 + ICH9, 2009)`, the same `q35` motherboard the XML asked for. The
kernel logged the same thing as its first line, with the version of the firmware QEMU supplies. This is
where `systemd-detect-virt` found its answer in lesson 1.

On a real PC these files name Dell, Lenovo or whoever built it, and a support technician reads them to
find a model number without opening the case. In a guest they name VirtualBox, VMware, Microsoft or
QEMU. **Software that refuses to run in a virtual machine usually looks here**, and so does a licence
check that counts machines.
