---
title: Where a VirtualBox machine lives
version: 1
---

Everything about `lab1` is in one folder:

```
ana@host:~$ ls ~/"VirtualBox VMs"/lab1
lab1.vbox
lab1.vbox-prev
lab1.vdi
ana@host:~$ grep -E "<(Memory|CPU|HardDisk) |<Adapter slot=.0." ~/"VirtualBox VMs"/lab1/lab1.vbox
        <HardDisk uuid="{2d68bc32-d25f-4071-9cf8-1d85af0f25e4}" location="lab1.vdi" format="VDI" type="Normal"/>
      <CPU count="2">
      <Memory RAMSize="2048"/>
        <Adapter slot="0" enabled="true" MACAddress="0800276D37CF" type="82540EM">
```

`lab1.vbox` is the machine's description, the counterpart of the XML libvirt keeps in lesson 3, and
`lab1.vbox-prev` is the version before the last change, kept in case the newest is damaged.
`lab1.vdi` is the disk. The description holds the disk by file name, the processors and the memory
as they were set, and the network card, with a MAC VirtualBox chose, `0800276D37CF`, or `08:00:27:6d:37:cf` written the
usual way. **Every VirtualBox MAC begins `08:00:27`**, as every QEMU one begins `52:54:00`, and the
card is an `82540EM`, an Intel model that every system has a driver for.

The folder is the machine. **To back one up, or move it to another computer, copy the whole folder
while the machine is switched off**, and on the other side add it with *Machine* → *Add*, which reads
the `.vbox`. Copying only the `.vdi` gets you the disk and loses the settings.

By default the folder is under *VirtualBox VMs* in your home, and on a laptop with a small system disk
the first thing worth changing is that: *File* → *Preferences* → *Default Machine Folder* can point at a
larger disk.
