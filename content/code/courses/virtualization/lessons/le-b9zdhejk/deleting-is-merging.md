---
title: Deleting a snapshot is a merge
version: 1
---

A layer cannot simply be deleted: it holds every write since the snapshot. Deleting the snapshot and
keeping the present means **merging the layer down** into the one below, which VMware calls
*consolidating* and libvirt calls a *block commit*. Merging into which layer is the question:

```
ana@host:~$ virsh blockcommit vm1 vda --active --pivot
error: internal error: unable to execute QEMU command 'block-commit': Could not open '/var/lib/libvirt/images/lab-base.qcow2': Permission denied

ana@host:~$ ls -l /var/lib/libvirt/images/lab-base.qcow2
-r--r--r-- 1 libvirt-qemu kvm 325386240 Sep 25 20:17 /var/lib/libvirt/images/lab-base.qcow2
ana@host:~$ virsh blockcommit vm1 vda --active --pivot --shallow

Successfully pivoted
ana@host:~$ virsh domblklist vm1
 Target   Source
---------------------------------------------
 vda      /var/lib/libvirt/images/vm1.qcow2

ana@host:~$ virsh snapshot-delete vm1 before-update --metadata && sudo rm /var/lib/libvirt/images/vm1.before-update
Domain snapshot before-update deleted

ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
128M -rw-r--r-- 1 libvirt-qemu kvm 1.3G Sep 25 20:28 vm1.qcow2
```

The first `blockcommit` tried to merge into the **bottom of the chain**, which is its default, and the
bottom here is `lab-base.qcow2`, the disk every guest in this course reads from. It failed only because
that file is read-only. **This is not hypothetical**: while this lesson was being prepared, the same
command, run against a base that was not read-only, wrote one guest's changes into the base of all of
them, and it had to be rebuilt. `lab.sh` has made the base read-only ever since.

`--shallow` merges one layer down, into `vm1.qcow2`, and `--pivot` switches the running guest onto it,
without stopping it. Then the snapshot's record and its now-empty file go. `vm1.qcow2` holds the
guest's changes, 128M, and the chain is back to two files.

Every hypervisor's *delete snapshot* button does a merge like this one, and it takes time in proportion
to the layer's size, while the guest runs. **Delete snapshots when the server is quiet**, and never
delete a layer's file by hand: the guest's newest data is in it.
