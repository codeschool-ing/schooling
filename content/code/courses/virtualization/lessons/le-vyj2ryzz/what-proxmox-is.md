---
title: What Proxmox VE is
version: 1
---

**Proxmox Virtual Environment** is a Linux distribution, based on Debian, whose only job is to run
virtual machines and containers. It is installed on a server from its own ISO, it takes over the whole
disk, and after installation the server shows a single line on its screen: the address of its web
interface, `https://` followed by the server's address and **port 8006**. Everything else is done from
a browser.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"What Proxmox VE is, as layers. At the bottom, a server&#x27;s hardware with VT-x or AMD-V. On it, Debian with Proxmox&#x27;s kernel and KVM. On that, QEMU for virtual machines and LXC for containers, side by side. Over all of it, the web interface on port 8006 and the commands qm, pct and vzdump. Beside the stack, the storage, local, LVM, ZFS, NFS or Ceph, and the cluster that makes several nodes one. To the right, this course&#x27;s lab for comparison: Ubuntu, libvirt and virsh, with the same QEMU underneath.\"><defs><marker id=\"px-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"440\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the web interface, port 8006</text><rect x=\"20\" y=\"56\" width=\"440\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"77\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">qm, pct, vzdump on the command line</text><rect x=\"20\" y=\"100\" width=\"214\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">QEMU: virtual machines</text><rect x=\"246\" y=\"100\" width=\"214\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">LXC: containers</text><rect x=\"20\" y=\"148\" width=\"440\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Debian, with Proxmox’s kernel and KVM</text><rect x=\"20\" y=\"190\" width=\"440\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a server’s hardware, with VT-x or AMD-V</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">storage: local, LVM, ZFS, NFS, Ceph</text><text x=\"20\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the cluster: several nodes as one</text><rect x=\"500\" y=\"100\" width=\"200\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"514\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">this course’s lab</text><text x=\"514\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Ubuntu, libvirt, virsh</text><text x=\"514\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the same QEMU underneath</text><path d=\"M498 144 L130 144\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#px-ah)\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "Proxmox is a Linux distribution whose whole job is to be a hypervisor, and its engine is the QEMU and KVM this course already uses. What it adds is everything around the engine: a web interface, storage, backups and a cluster."}
```

It runs two kinds of guest. **Virtual machines** are QEMU with KVM, lesson 2's type 1 argument made
concrete. **Containers** are LXC, which lesson 13 compares with virtual machines. Around them it adds
**storage** for disks and ISOs, **backups**, a **firewall**, users with permissions, and a **cluster**
that joins several servers into one interface.

Proxmox is free software under the AGPL. The company sells **subscriptions**, which give access to the
*enterprise* package repository and to support. Without one, the server uses the *no-subscription*
repository, which is free and slightly less tested, and the web interface shows a *No valid
subscription* message at every login. For a lab or a small office that message is the whole cost, and
it is a message, not a limit.

You log in as `root` with the realm *Linux PAM standard authentication*, which is the server's own
root password. Every machine gets a **number**, starting at `100`, and the number is its name as far
as the files and commands are concerned.

Proxmox is not installed on this course's host, which is itself a virtual machine without VT-x, as
lesson 2 found. What the lab does have is the engine Proxmox runs, and the next three sections look at
it through the names Proxmox gives each part.
