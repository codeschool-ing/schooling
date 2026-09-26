---
title: VMDK, the disk everybody reads
version: 1
---

**VMDK** is VMware's disk format, and it became the common language of disk images: VirtualBox, QEMU
and most cloud importers read it. `qemu-img` writes one from the lab's base
disk:

```
ana@host:~$ qemu-img convert -O vmdk /var/lib/libvirt/images/lab-base.qcow2 ~/lab.vmdk
ana@host:~$ qemu-img info ~/lab.vmdk | head -5
image: /home/ana/lab.vmdk
file format: vmdk
virtual size: 3.5 GiB (3758096384 bytes)
disk size: 816 MiB
cluster_size: 65536
ana@host:~$ ls -lh /var/lib/libvirt/images/lab-base.qcow2 ~/lab.vmdk
-rw-r--r-- 1 ana          ana 817M Sep 25 19:24 /home/ana/lab.vmdk
-rw-r--r-- 1 libvirt-qemu kvm 318M Sep 25 18:28 /var/lib/libvirt/images/lab-base.qcow2
```

The same 3.5 GiB disk, 817M as a VMDK against 318M as Ubuntu's compressed qcow2. Like qcow2 and VDI,
this VMDK is *sparse*: space the guest never wrote is not stored.

Workstation's wizard also offers to **split the disk into multiple files**, and old machines are
almost always made that way. This is what split means:

```
ana@host:~$ mkdir -p ~/split && qemu-img convert -O vmdk -o subformat=twoGbMaxExtentSparse /var/lib/libvirt/images/lab-base.qcow2 ~/split/lab.vmdk && ls -lh ~/split
total 817M
-rw-r--r-- 1 ana ana 770M Sep 25 19:24 lab-s001.vmdk
-rw-r--r-- 1 ana ana  48M Sep 25 19:24 lab-s002.vmdk
-rw-r--r-- 1 ana ana  512 Sep 25 19:24 lab.vmdk
ana@host:~$ tr -d '\0' < ~/split/lab.vmdk
# Disk DescriptorFile
version=1
CID=cf663534
parentCID=ffffffff
createType="twoGbMaxExtentSparse"

# Extent description
RW 4194304 SPARSE "lab-s001.vmdk"
RW 3145728 SPARSE "lab-s002.vmdk"

# The Disk Data Base
#DDB

ddb.virtualHWVersion = "4"
ddb.geometry.cylinders = "7281"
ddb.geometry.heads = "16"
ddb.geometry.sectors = "63"
ddb.adapterType = "ide"
ddb.toolsVersion = "2147483647"
```

`lab.vmdk` is now a 512-byte text file, a **descriptor**, and the data is in `lab-s001.vmdk` and
`lab-s002.vmdk`. The descriptor's `RW` lines list them with their sizes in 512-byte sectors:
4194304 sectors is exactly 2 GiB, and 3145728 is the remaining 1.5 GiB. The limit comes from file systems
like FAT32, which cannot hold a file of 4 GiB or more, and from the days when disks were moved on them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A split VMDK. The file lab.vmdk is a descriptor, 512 bytes of text. It lists two extents: lab-s001.vmdk, 4194304 sectors, the first 2 GiB of the disk, taking 770M on the host; and lab-s002.vmdk, 3145728 sectors, the remaining 1.5 GiB, taking 48M.\"><defs><marker id=\"ex-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"240\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lab.vmdk</text><text x=\"34\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the descriptor: text, 512 bytes</text><rect x=\"360\" y=\"20\" width=\"340\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">lab-s001.vmdk   770M</text><text x=\"374\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RW 4194304 SPARSE</text><text x=\"374\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">first 2 GiB of the disk</text><path d=\"M262 50 L358 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path><rect x=\"360\" y=\"110\" width=\"340\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">lab-s002.vmdk   48M</text><text x=\"374\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RW 3145728 SPARSE</text><text x=\"374\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the remaining 1.5 GiB</text><path d=\"M262 50 L358 145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ex-ah)\"></path></svg>", "caption": "A split disk is one small text file that names its pieces, each covering at most 2 GiB. Open the descriptor and the hypervisor reads the pieces; lose one piece and the disk is gone."}
```

Two things follow for support. **Copy every piece**: a split disk missing one `-s00N.vmdk` does not
open, and a customer who "copied the VM" from a list sorted by size may have left the small pieces
behind. And **never edit the descriptor by hand** unless you know why; it is text, and that is the
temptation.
