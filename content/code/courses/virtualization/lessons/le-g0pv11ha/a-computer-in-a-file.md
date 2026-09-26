---
title: A computer in a file
version: 1
---

A **virtual machine**, or VM, is a computer made of software, running on a real computer. The real
one is the **host** and the VM is a **guest**. The program that makes the guest believe it has
hardware is the **hypervisor**. Throughout this course the host is a computer called `host`, running
Ubuntu, and the hypervisor is **QEMU**, driven by a management layer called **libvirt**. Lessons 4
and 5 do the same things with VirtualBox and VMware, which are what most people install on Windows
and on a Mac.

A new computer needs a disk first. This one is a file:

```
ana@host:~$ cd /var/lib/libvirt/images && sudo qemu-img create -f qcow2 -b lab-base.qcow2 -F qcow2 vm1.qcow2 8G
Formatting 'vm1.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=8589934592 backing_file=lab-base.qcow2 backing_fmt=qcow2 lazy_refcounts=off refcount_bits=16
```

`qemu-img` made an 8 GiB disk, `size=8589934592` bytes, in the **qcow2** format, QEMU's own. It is 8
GiB as far as the guest will ever know, and almost nothing on the host, because a qcow2 file only
grows when something is written into it. The `-b lab-base.qcow2` part makes it an **overlay**: it starts
as a copy of a base disk that already has Ubuntu installed on it, without copying anything.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"One disk made of two files. vm1 sees a single disk, vda, of 8G. Underneath it, vm1.qcow2, 25M so far, holds only vm1&#x27;s own changes, and points at lab-base.qcow2, 318M, the base, which is shared and never written. A block vm1 never changed is read from the base.\"><defs><marker id=\"ov-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the one disk vm1 sees: vda, 8G</text><rect x=\"20\" y=\"92\" width=\"330\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">vm1.qcow2   25M</text><text x=\"36\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vm1’s own changes, and only those</text><rect x=\"20\" y=\"166\" width=\"680\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">lab-base.qcow2   318M</text><text x=\"36\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the base, shared and never written</text><path d=\"M185 66 L185 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ov-ah)\"></path><path d=\"M185 150 L185 164\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ov-ah)\"></path><path d=\"M530 164 L530 66\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ov-ah)\" stroke-dasharray=\"4 4\"></path><text x=\"380\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a block vm1 never changed is read from the base</text></svg>", "caption": "The new disk is a list of differences from the base. It starts almost empty and grows only as the guest writes, which is why it held 25M when the guest had already booted."}
```

Then the machine itself. `virt-install` describes it to libvirt, how much memory, how many
processors, which disks and which network, and starts it:

```
ana@host:~$ sudo virt-install --name vm1 --virt-type qemu --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/vm1.qcow2,bus=virtio --disk /var/lib/libvirt/images/vm1-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole
WARNING  Requested memory 1024 MiB is less than the recommended 3072 MiB for OS ubuntu24.04

Starting install...
Creating domain...                                          |    0 B  00:00     
Domain creation completed.
ana@host:~$ virsh list
 Id   Name   State
----------------------
 5    vm1    running
```

`--memory 1024` is 1 GiB of memory and `--vcpus 2` is two processors. The warning is honest: Ubuntu
asks for more than 1 GiB for a desktop, and this guest has no desktop. The second disk,
`vm1-seed.img`, is a small one that gives the guest its name and lets ana log in on its first boot.
`virsh list` is libvirt's list of running guests, and `vm1` is on it.

`--virt-type qemu` is there because of the computer this course was recorded on. **It is itself a
virtual machine, and it does not pass the processor's virtualisation features on**, so QEMU has to
imitate the guest's processor in software. Everything works, only slower. On your own computer, if
the processor has VT-x or AMD-V switched on, leave that option out or write `--virt-type kvm`, and the
guest runs on the real processor. Lesson 2 is about exactly that difference.
