---
title: Not only VMware’s
version: 1
---

A VMDK is only a disk, and any hypervisor that reads the format can boot from it. Here QEMU starts a
guest whose disk is a VMDK, with the same `virt-install` as lesson 1 and `format=vmdk`:

```
ana@host:~$ cd /var/lib/libvirt/images && sudo qemu-img convert -O vmdk lab-base.qcow2 vmw1.vmdk
ana@host:~$ sudo virt-install --name vmw1 --virt-type qemu --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/vmw1.vmdk,format=vmdk,bus=virtio --disk /var/lib/libvirt/images/vmw1-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole
WARNING  Requested memory 1024 MiB is less than the recommended 3072 MiB for OS ubuntu24.04

Starting install...
Creating domain...                                          |    0 B  00:00     
Domain creation completed.
ana@vmw1:~$ hostname; lsblk -d -o NAME,SIZE,TYPE /dev/vda
vmw1
NAME  SIZE TYPE
vda   3.5G disk
ana@host:~$ virsh domblklist vmw1
 Target   Source
-------------------------------------------------
 vda      /var/lib/libvirt/images/vmw1.vmdk
 vdb      /var/lib/libvirt/images/vmw1-seed.img
```

`vmw1` booted, answered ssh, and sees an ordinary 3.5G disk. `virsh domblklist` shows the file is the
`.vmdk`. The guest cannot tell, and does not care, which format its hypervisor keeps its disk in.

That is what makes the format useful to a technician. **A disk from a dead VMware install can be
opened by VirtualBox or QEMU**, and a machine that has to move between hypervisors can go as its disk
alone, if nothing else survives. What does not come along is the `.vmx`: the settings have to be made
again on the other side, and the guest may need its drivers for the new virtual hardware.
