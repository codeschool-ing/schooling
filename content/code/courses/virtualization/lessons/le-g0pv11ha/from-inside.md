---
title: From inside
version: 1
---

ana logs in to the guest with `ssh vm1`, as she would to any server on the network, and asks it what
it is:

```
ana@vm1:~$ hostname; systemd-detect-virt
vm1
qemu
ana@vm1:~$ lscpu | grep -E "^(CPU\(s\)|Model name|Hypervisor vendor|Virtualization type)"
CPU(s):                                  2
Model name:                              QEMU Virtual CPU version 2.5+
ana@vm1:~$ free -h | head -2
               total        used        free      shared  buff/cache   available
Mem:           961Mi       231Mi       673Mi       772Ki       203Mi       729Mi
ana@vm1:~$ lsblk -d -o NAME,SIZE,TYPE
NAME  SIZE TYPE
vda     8G disk
vdb   128K disk
ana@vm1:~$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 ::1/128 
enp1s0           UP             192.168.122.165/24 metric 100 fe80::5054:ff:fec7:f76e/64 
```

To itself, `vm1` is a computer. It has a name, `vm1`. It has **2 processors**, the two `--vcpus`, whose
model is `QEMU Virtual CPU version 2.5+`, a processor that exists only in QEMU. It has **961Mi of
memory**: the 1 GiB it was given, less what the kernel keeps for itself before `free` counts. It has
an **8G disk** called `vda`, the overlay file, and a small `vdb`, the seed disk. It has a network card,
`enp1s0`, with the address `192.168.122.165`.

Nothing in that list says "virtual" except the names, and a guest is not meant to be able to tell.
The one line that does say it is `systemd-detect-virt`, which answered `qemu`: it looks for clues a
hypervisor leaves, such as the maker's name in the firmware's tables. The `grep` also asked for
`Hypervisor vendor` and `Virtualization type`, and `lscpu` printed neither, because QEMU's software
processor did not announce itself. With KVM, lesson 2 shows it does.

**Everything you already know how to do on a Linux machine works here unchanged**: users, packages,
services, logs, the network. A guest is somewhere to do those things where a
mistake costs nothing.
