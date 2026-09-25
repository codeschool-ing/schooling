---
title: A full clone
version: 1
---

A **clone** is a new virtual machine made by copying an existing one. `virt-clone` does it for libvirt,
with the original switched off so its disk is not changing:

```
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ sudo virt-clone --original vm1 --name vm2 --auto-clone
Allocating 'vm2.qcow2'                                      | 490 MB  00:00 ... 

Clone 'vm2' created successfully.
ana@host:~$ sudo ls -lsh /var/lib/libvirt/images/vm1.qcow2 /var/lib/libvirt/images/vm2.qcow2
 27M -rw-r--r-- 1 root root  27M Sep 25 20:50 /var/lib/libvirt/images/vm1.qcow2
804M -rw------- 1 root root 804M Sep 25 20:50 /var/lib/libvirt/images/vm2.qcow2
ana@host:~$ virsh domiflist vm1; virsh domiflist vm2
 Interface   Type      Source    Model    MAC
-------------------------------------------------------------
 -           network   default   virtio   52:54:00:bb:a6:55

 Interface   Type      Source    Model    MAC
-------------------------------------------------------------
 -           network   default   virtio   52:54:00:c9:25:bc

ana@host:~$ virsh start vm1 && virsh start vm2
Domain 'vm1' started

Domain 'vm2' started
```

The clone got **a disk of its own**, and a large one: vm1's disk was a 27M overlay, and vm2's is
804M, because a **full clone** copies everything the guest can read, the base underneath included.
It is independent: the original can be deleted and the clone does not notice.

`virt-clone` also changed the two things that belong to the hypervisor. vm2 has **a new MAC**,
`52:54:00:c9:25:bc` where vm1 has `52:54:00:bb:a6:55`, and a new UUID in libvirt. Two cards with one MAC on one network would
fight over every packet, so every hypervisor changes it when cloning, unless told not to: VirtualBox's
clone dialog calls it the *MAC address policy*, and keeping the old MACs is only right for a clone that
will never run beside its original.

Both were started, and that is where it went wrong.
