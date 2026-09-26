---
title: Starting it, and taking it elsewhere
version: 1
---

On your computer, **Start** opens the guest in a window, and `VBoxManage startvm lab1 --type headless`
starts it with no window at all, for guests you reach over the network. On this one:

```
ana@host:~$ VBoxManage startvm lab1 --type headless
VBoxManage: error: The virtual machine 'lab1' has terminated unexpectedly during startup with exit code 1 (0x1)
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component MachineWrap, interface IMachine
Waiting for VM "lab1" to power on...
```

`terminated unexpectedly during startup` is the missing driver from section 02, and it is the message
a customer reads out on the phone when it is missing on theirs. The machine's description is fine; it
is the host that cannot run it.

What does not need the driver is moving machines between hypervisors. VirtualBox reads other
hypervisors' disks, and the lab's QEMU base disk becomes a VirtualBox one with one command:

```
ana@host:~$ cd ~/"VirtualBox VMs"/lab1 && VBoxManage clonemedium /var/lib/libvirt/images/lab-base.qcow2 ubuntu.vdi --format VDI
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Clone medium created in format 'VDI'. UUID: 424c8fb9-e47d-4b5f-9f6d-7f0276cd0400
ana@host:~$ ls -lh /var/lib/libvirt/images/lab-base.qcow2 ~/"VirtualBox VMs"/lab1/ubuntu.vdi
-rw------- 1 ana          ana 860M Sep 25 19:15 /home/ana/VirtualBox VMs/lab1/ubuntu.vdi
-rw-r--r-- 1 libvirt-qemu kvm 318M Sep 25 18:28 /var/lib/libvirt/images/lab-base.qcow2
```

The copy is 860M against the base's 318M, because Ubuntu's cloud image stores its blocks compressed
and a VDI does not. The contents are the same Ubuntu. And a whole machine, description and disk, is
exported as an **OVA**:

```
ana@host:~$ VBoxManage export lab1 -o ~/lab1.ova
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Successfully exported 1 machine(s).
ana@host:~$ tar tvf ~/lab1.ova
-rw-r----- vboxovf10/vbox_v7.0.16r162802 6160 2026-09-25 19:15 lab1.ovf
-rw-rw---- vboxovf10/vbox_v7.0.16r162802 70144 2026-09-25 19:15 lab1-disk001.vmdk
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"How a machine moves between hypervisors. On the left, QEMU and libvirt keep disks as qcow2. VBoxManage clonemedium copies one into VirtualBox&#x27;s own format, VDI. VBoxManage export then packs the machine as an OVA: a description in OVF and its disk as VMDK, which any hypervisor that imports OVF can read, VMware among them, in lesson 5.\"><defs><marker id=\"fm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">QEMU and libvirt</text><text x=\"32\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">lab-base.qcow2</text><rect x=\"270\" y=\"40\" width=\"150\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"282\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VirtualBox</text><text x=\"282\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ubuntu.vdi</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"532\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lab1.ova</text><text x=\"532\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lab1.ovf</text><text x=\"532\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lab1-disk001.vmdk</text><path d=\"M172 70 L268 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fm-ah)\"></path><text x=\"220\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">VBoxManage clonemedium</text><path d=\"M422 70 L518 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fm-ah)\"></path><text x=\"470\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">VBoxManage export</text><text x=\"610\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">any hypervisor that imports OVF</text><text x=\"610\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">import, lesson 5</text></svg>", "caption": "Each hypervisor keeps disks in a format of its own, and each can read the others’. OVF is the one meant for carrying a whole machine, description and disks, from one to another."}
```

An OVA is a `tar` file holding an **OVF**, a description of the machine that other hypervisors can
read, and the disk as a **VMDK**, VMware's format. It is how appliances are distributed, and how a
machine made in VirtualBox reaches VMware, which is the next lesson. *File* → *Import Appliance* does
the opposite.
