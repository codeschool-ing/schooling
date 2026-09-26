---
title: Running guests on a server
version: 1
---

A server's guests have to come back by themselves after the server reboots, at night, with nobody
watching. In libvirt that is one command:

```
ana@host:~$ virsh autostart vm1
Domain 'vm1' marked as autostarted

ana@host:~$ virsh dominfo vm1 | grep -E "^(Name|State|Autostart)"
Name:           vm1
State:          running
Autostart:      enable
```

Proxmox has the same switch as *Start at boot* in a machine's *Options*, with a start order and a delay,
so the database comes up before the application that needs it.

In the web interface, *Create VM* walks through tabs that are this course's lessons in order:
*General* (the number and name), *OS* (the ISO), *System* (firmware and the guest agent, lesson 3),
*Disks*, *CPU* and *Memory* (lesson 8), *Network* (the bridge). A running machine has a *Console* tab
that shows its screen in the browser, which is how you install a system on a server nobody sits in
front of. On the command line, the same work is `qm` for machines and `pct` for containers:

```sh
qm create 100 --name lab1 --ostype l26 --memory 2048 --cores 2 \
   --scsihw virtio-scsi-pci --scsi0 local-lvm:32 \
   --ide2 local:iso/ubuntu-24.04-live-server-amd64.iso,media=cdrom \
   --net0 virtio,bridge=vmbr0 --boot 'order=scsi0;ide2'   # a VM, id 100
qm start 100                                   # start it
qm list                                        # every VM on this node
qm config 100                                  # its settings, from /etc/pve/qemu-server/100.conf
qm showcmd 100 --pretty                        # the QEMU command line Proxmox will run
qm snapshot 100 clean                          # a snapshot called clean, lesson 9
qm template 100                                # turn it into a template, lesson 10
qm clone 100 101 --name lab2 --full            # a full clone of it, id 101
qm disk import 101 lab-base.qcow2 local-lvm    # bring a disk from another hypervisor
pct create 200 local:vztmpl/TEMPLATE.tar.zst --hostname ct1 --memory 512   # a container
vzdump 100 --storage local --mode snapshot     # back VM 100 up while it runs
```

**None of these were run for this lesson.** `TEMPLATE` stands for a container template downloaded from
the web interface, whose file name changes with every release.

Two features are why a company chooses a server hypervisor over a laptop one. **Backups** of running
machines, with `vzdump` or a separate Proxmox Backup Server, on a schedule. And **clusters**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A Proxmox cluster of three nodes, pve1, pve2 and pve3, all connected to shared storage where the guests&#x27; disks live. A guest moves from pve1 to pve2 by live migration and keeps running while it moves. With three nodes, two can outvote one, which is what lets the cluster decide which node is really down.\"><defs><marker id=\"cl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pve1</text><text x=\"80\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">node</text><rect x=\"34\" y=\"56\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vm 100</text><path d=\"M120 102 L120 158\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cl-ah)\" marker-start=\"url(#cl-ah)\"></path><rect x=\"260\" y=\"20\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pve2</text><text x=\"320\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">node</text><rect x=\"274\" y=\"56\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"286\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">vm 100</text><path d=\"M360 102 L360 158\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cl-ah)\" marker-start=\"url(#cl-ah)\"></path><rect x=\"500\" y=\"20\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pve3</text><text x=\"560\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">node</text><path d=\"M600 102 L600 158\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cl-ah)\" marker-start=\"url(#cl-ah)\"></path><path d=\"M 126 70 C 180 70, 220 70, 252 70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cl-ah)\"></path><rect x=\"20\" y=\"160\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shared storage: the disks live here</text><text x=\"20\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">live migration: the guest keeps running while it moves</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">three nodes, so two can outvote one</text></svg>", "caption": "In a cluster the disks are on storage every node reaches, so moving a guest only moves its memory and processor state. That is what makes maintenance on one node possible without switching anybody off."}
```

With three or more servers joined in a cluster and the disks on shared storage, a running machine can
be **migrated** from one server to another without being switched off, and with *high availability* on,
the cluster starts it again elsewhere when its server dies. Three is the minimum that matters: with
two, when they lose sight of each other neither can tell whether the other is dead or just unreachable,
and a guest started twice on one shared disk destroys it.
