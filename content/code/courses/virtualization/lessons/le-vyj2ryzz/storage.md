---
title: Storage
version: 1
---

Disks, ISOs and backups have to live somewhere, and a hypervisor that manages servers gives those
places names. libvirt calls them **pools**, and the lab has one, the images folder:

```
ana@host:~$ virsh pool-list --all --details
 Name     State     Autostart   Persistent   Capacity     Allocation   Available
-----------------------------------------------------------------------------------
 images   running   yes         yes          251.97 GiB   17.42 GiB    234.55 GiB

ana@host:~$ virsh vol-list images --details
 Name                                      Path                                                              Type      Capacity   Allocation
----------------------------------------------------------------------------------------------------------------------------------------------
 lab-base.qcow2                            /var/lib/libvirt/images/lab-base.qcow2                            file      3.50 GiB   316.42 MiB
 SHA256SUMS                                /var/lib/libvirt/images/SHA256SUMS                                file      2.12 KiB   4.00 KiB
 ubuntu-24.04-minimal-cloudimg-amd64.img   /var/lib/libvirt/images/ubuntu-24.04-minimal-cloudimg-amd64.img   file      3.50 GiB   252.13 MiB
 vm1-seed.img                              /var/lib/libvirt/images/vm1-seed.img                              unknown   unknown    unknown
 vm1.qcow2                                 /var/lib/libvirt/images/vm1.qcow2                                 file      8.00 GiB   25.82 MiB
```

The pool is a folder on a disk of 251.97 GiB, and each file in it is a **volume** with two sizes:
**Capacity**, what the guest is told, and **Allocation**, what it takes on the host. vm1's disk is 8.00
GiB to the guest and 25.82 MiB on the host, lesson 1's thin disk again.

Proxmox calls the same idea a **storage**, and a fresh installation has two:

- **`local`**, a folder, `/var/lib/vz`, for ISOs, container templates and backups.
- **`local-lvm`**, an LVM *thin pool*, for the disks of virtual machines. Thin, like the qcow2 files
  here: space is taken as guests write.

Others are added in *Datacenter* → *Storage*: a ZFS pool, an NFS share on a file server, or Ceph spread
across the nodes of a cluster. **The storage a disk lives on decides what can be done with it**: a
snapshot needs a storage that supports snapshots, and moving a running machine to another server is
simplest when both servers reach the same shared storage.
