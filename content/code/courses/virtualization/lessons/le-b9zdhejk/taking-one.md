---
title: Taking one
version: 1
---

Inside vm1 there is a file worth keeping. Then a snapshot, from the host:

```
ana@vm1:~$ echo "checked, all fine" > notes.txt; cat notes.txt
checked, all fine
ana@host:~$ virsh snapshot-create-as vm1 clean --description "before the change"
Domain snapshot clean created
ana@host:~$ virsh snapshot-list vm1
 Name    Creation Time               State
----------------------------------------------
 clean   2026-09-25 20:26:55 -0300   running

ana@host:~$ sudo qemu-img info -U /var/lib/libvirt/images/vm1.qcow2 | sed -n "/^Snapshot list/,/^Format/p" | head -3
Snapshot list:
ID        TAG               VM SIZE                DATE     VM CLOCK     ICOUNT
1         clean             426 MiB 2026-09-25 20:26:55 00:01:57.460           
ana@host:~$ ls -lsh /var/lib/libvirt/images/vm1.qcow2
453M -rw-r--r-- 1 libvirt-qemu kvm 453M Sep 25 20:26 /var/lib/libvirt/images/vm1.qcow2
```

`snapshot-create-as` took a snapshot called `clean` of a **running** guest, and `snapshot-list` shows its
state as `running`: it holds the disk as it was and the **memory** as it was too, so returning to it
puts the guest back mid-flight, programs open, rather than switched off. `qemu-img info` shows where it
went: inside `vm1.qcow2` itself, with a `VM SIZE` of 426 MiB, the saved memory. The file grew to
453M.

A snapshot of a guest that is switched off holds only the disk, and is smaller and quicker. Both are
called snapshots everywhere: VirtualBox's *Take*, VMware's *Snapshot Manager*, Proxmox's `qm
snapshot`. Hyper-V calls them *checkpoints*, lesson 7.

**Give it a name that says why it exists**, and a description if the name cannot. In a month, `clean`
means nothing and `before-printer-driver-3.2` still does.
