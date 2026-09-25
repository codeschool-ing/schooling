---
title: Thin disks, and getting space back
version: 1
---

A thin disk grows as the guest writes. What happens when the guest deletes?

```
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
27M -rw-r--r-- 1 libvirt-qemu kvm 27M Sep 25 20:04 vm1.qcow2
ana@vm1:~$ dd if=/dev/urandom of=big bs=1M count=300 status=none && sync && ls -lh big
-rw-rw-r-- 1 ana ana 300M Sep 25 20:04 big
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
327M -rw-r--r-- 1 libvirt-qemu kvm 327M Sep 25 20:04 vm1.qcow2
ana@vm1:~$ rm big && sync && sudo fstrim -v /
/: 6.2 GiB (6664396800 bytes) trimmed
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
327M -rw-r--r-- 1 libvirt-qemu kvm 327M Sep 25 20:04 vm1.qcow2
```

The file grew from 27M to 327M when the guest wrote 300 MB, and stayed at 327M after the
guest deleted it. The first column of `ls -lsh` is the space the file really takes on the host, the
second is its apparent size, and neither moved. **Deleting a file frees space inside the guest's file
system and nowhere else**; the disk underneath still holds the blocks, because nothing told it they are
free.

What tells it is **TRIM**, the same command an SSD receives, and `fstrim` sends it for every free block.
The guest reported `6.2 GiB trimmed`, and the host ignored it: libvirt's default is to discard nothing.
The setting that makes the host listen is `discard='unmap'` on the disk, and like most hardware
settings it needs the guest switched off and on, section 07. After that:

```
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
212M -rw-r--r-- 1 libvirt-qemu kvm 332M Sep 25 20:07 vm1.qcow2
ana@vm1:~$ sudo fstrim -v /
/: 6.2 GiB (6659100672 bytes) trimmed
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
33M -rw-r--r-- 1 libvirt-qemu kvm 332M Sep 25 20:07 vm1.qcow2
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"vm1.qcow2 on the host, in five moments. New: 27M. After the guest writes 300 MB: 327M. After the guest deletes the file and runs fstrim, which the host ignores: still 327M. After discard=unmap is set and the guest restarted: 212M. After fstrim again, now honoured: 33M.\"><defs><marker id=\"tr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"140.09174311926606\" width=\"60\" height=\"9.908256880733944\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"60\" y=\"130.09174311926606\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">27M</text><text x=\"30\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">new</text><rect x=\"168\" y=\"30.0\" width=\"60\" height=\"120.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"198\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">327M</text><text x=\"168\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300 MB written</text><rect x=\"306\" y=\"30.0\" width=\"60\" height=\"120.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"336\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">327M</text><text x=\"306\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">deleted, fstrim ignored</text><rect x=\"444\" y=\"72.20183486238533\" width=\"60\" height=\"77.79816513761467\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"474\" y=\"62.201834862385326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">212M</text><text x=\"444\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">discard=unmap, restarted</text><rect x=\"582\" y=\"137.88990825688074\" width=\"60\" height=\"12.110091743119266\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"612\" y=\"127.88990825688073\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">33M</text><text x=\"582\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fstrim honoured</text></svg>", "caption": "A guest deleting a file frees space inside the guest and nowhere else. The host gets it back only when the guest says so, with TRIM, and only when the host is set to listen."}
```

The space taken dropped to 33M, while the apparent size stayed where it was. Some of it had already
come back during the restart, and `fstrim` returned the rest. Ubuntu runs `fstrim` once a week by itself,
so a guest with `discard='unmap'` keeps its file close to what it really holds. Without it, a busy lab's
disks only ever grow.
