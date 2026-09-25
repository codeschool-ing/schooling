---
title: Virtual processors
version: 1
---

vm1 was made with two virtual processors, **vCPUs**, and libvirt can say what each is doing:

```
ana@host:~$ virsh vcpucount vm1
maximum      config         2
maximum      live           2
current      config         2
current      live           2

ana@host:~$ virsh vcpuinfo vm1 | grep -E "^(VCPU|CPU|State|CPU time)"
VCPU:           0
CPU:            3
State:          running
CPU time:       90.2s
CPU Affinity:   yyyy
VCPU:           1
CPU:            1
State:          running
CPU time:       90.4s
CPU Affinity:   yyyy
ana@vm1:~$ nproc
2
```

`vcpucount` shows four numbers because a guest has a **maximum**, fixed when it starts, and a
**current** count that can go up to it, and each exists both in the saved description (`config`) and in
the running guest (`live`). `vcpuinfo` shows that each vCPU is running **on some real processor of the
host**: at that moment, vCPU 0 on host processor 3 and vCPU 1 on processor 1. `CPU Affinity:
yyyy` means either may run on any of the host's four; the host's scheduler moves them as it moves any
thread. Each has used about 90.2 seconds of processor time, most of it booting under imitation.

So a vCPU is a promise of turns, not a processor set aside. Two guests with two vCPUs each on a host
with four processors fit; ten of them also start, and take turns, and each runs slower. That is fine for
guests that are mostly idle, which is most of a lab, and bad for guests that are all busy at once.
Inside, `nproc` says 2, and the guest has no way of knowing it is sharing.

Two rules follow. **Give a guest as many vCPUs as its work uses, not more**: an idle vCPU costs little,
but a guest with eight busy threads on a host with four processors is slower than the same guest with
four. And **never give one guest all the host's processors**, lesson 4's rule, because the host has
work of its own, including running the guest's devices.
