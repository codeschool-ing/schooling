---
title: How a snapshot is stored
version: 1
---

The snapshots above lived inside `vm1.qcow2`. The other way to store one is as a **layer**: the current
disk is frozen, and a new file is put on top of it to take every write from then on. It is how VMware's
`-000001.vmdk` files and Hyper-V's `.avhdx` files work, and libvirt makes one with `--disk-only`:

```
ana@host:~$ virsh snapshot-create-as vm1 before-update --disk-only --atomic
Domain snapshot before-update created
ana@host:~$ virsh domblklist vm1
 Target   Source
-----------------------------------------------------
 vda      /var/lib/libvirt/images/vm1.before-update

ana@vm1:~$ dd if=/dev/urandom of=big bs=1M count=100 status=none && sync
ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2 vm1.before-update
106M -rw------- 1 libvirt-qemu kvm 106M Sep 25 20:28 vm1.before-update
 27M -rw-r--r-- 1 libvirt-qemu kvm 1.3G Sep 25 20:28 vm1.qcow2
ana@host:~$ sudo qemu-img info -U --backing-chain /var/lib/libvirt/images/vm1.before-update | grep -E "^(image|backing file):"
image: /var/lib/libvirt/images/vm1.before-update
backing file: /var/lib/libvirt/images/vm1.qcow2
image: /var/lib/libvirt/images/vm1.qcow2
backing file: /var/lib/libvirt/images/lab-base.qcow2
image: /var/lib/libvirt/images/lab-base.qcow2
```

The guest's disk is now `vm1.before-update`, and when the guest wrote 100 MB, the new file took it,
106M, while `vm1.qcow2` stayed at 27M. `--backing-chain` shows the chain: the new layer reads from
`vm1.qcow2`, which reads from the base. It is lesson 1's overlay one level higher.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"The chain of files behind vm1 after an external snapshot. At the top, vm1.before-update, 106M, where new writes land. Under it, vm1.qcow2, 27M, vm1&#x27;s disk as it was, frozen by the snapshot. At the bottom, lab-base.qcow2, the shared base, read-only. Deleting the snapshot means merging the top layer down. The default commit goes into the bottom of the chain, the shared base, and was refused. With --shallow it goes one layer down, into vm1.qcow2.\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"330\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">vm1.before-update   106M</text><text x=\"34\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">new writes land here</text><rect x=\"20\" y=\"92\" width=\"330\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">vm1.qcow2   27M</text><text x=\"34\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vm1’s disk, frozen by the snapshot</text><rect x=\"20\" y=\"168\" width=\"330\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lab-base.qcow2</text><text x=\"34\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the shared base, read-only</text><path d=\"M 352 42 C 420 42, 420 110, 352 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"462\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">--shallow: one layer down</text><path d=\"M 352 36 C 480 36, 480 190, 352 190\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"500\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">default commit: into the bottom of the chain</text><text x=\"500\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Permission denied</text></svg>", "caption": "Deleting an external snapshot is a merge, and the question is into which layer. The default answer is the bottom one, which here is every guest’s base."}
```

That explains the two classic complaints about snapshots on VMware and Hyper-V servers. **A snapshot
left in place grows for as long as it exists**, because every write since it was taken lands in its
layer; a forgotten one can fill a datastore. And **every read may have to look through each layer**,
so a machine with a long chain of old snapshots gets slower.
