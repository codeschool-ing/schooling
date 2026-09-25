---
title: Tuning it
version: 1
---

A few settings decide whether a guest is pleasant or painful, and most of them are about telling the
guest the truth about what it is running on:

```
ana@host:~$ VBoxManage modifyvm lab1 --paravirtprovider kvm --ioapic on --clipboard-mode bidirectional --boot1 disk --boot2 dvd --boot3 none --boot4 none
ana@host:~$ VBoxManage showvminfo lab1 --machinereadable | grep -E "^(memory|cpus|paravirtprovider|graphicscontroller|vram|nic1|clipboard|boot1|boot2|\"SATA-0-0\")="
memory=2048
vram=16
cpus=2
boot1="disk"
boot2="dvd"
paravirtprovider="kvm"
graphicscontroller="vmsvga"
"SATA-0-0"="/home/ana/VirtualBox VMs/lab1/lab1.vdi"
nic1="nat"
clipboard="bidirectional"
```

- **`--paravirtprovider kvm`** lets a Linux guest know it is a guest, so it can use cheaper ways of
  keeping time and waiting instead of pretending to be alone on a real machine. `hyperv` does the same
  for a Windows guest. The type from section 03 usually sets this already.
- **`--ioapic on`** is needed for more than one processor. VirtualBox turns it on for most modern types.
- **`graphicscontroller="vmsvga"`** is what VirtualBox recommends for Linux guests; for a Windows guest
  it recommends **VBoxSVGA**. The wrong one gives a small, fixed screen that will not resize.
- **Boot order**: `boot1="disk"` and `boot2="dvd"` start from the disk and fall back to the DVD. While
  installing, the DVD goes first; afterwards, the disk, or the guest boots the installer again.
- **`clipboard="bidirectional"`** shares the clipboard both ways, and like the screen resizing and
  shared folders, it only works once the guest has the **Guest Additions**, lesson 3's agent under
  VirtualBox's name. They are installed from *Devices* → *Insert Guest Additions CD image* in the
  guest's window, and on a Linux guest they need the guest's kernel headers to build.

And two rules about the numbers. **Never give a guest as many processors as the host has**: the host
and its other guests still need some, and VirtualBox draws the slider in red past what is safe.
**Memory in the guest is memory out of the host**: 2048 MB here is 2048 MB the host cannot use while
the guest runs, plus the hypervisor's own.
