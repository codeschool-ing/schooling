---
title: Creating a machine
version: 1
---

In the window, a machine is made with **New**, and the wizard asks five things: a **name** and where to
keep it, an **ISO** to install from, the **type and version** of the system, the **memory and
processors**, and a **hard disk**. Recent versions offer an *unattended installation* when they
recognise the ISO, which answers the installer's questions for you with a user name and password you
type into the wizard.

Each of those has a `VBoxManage` equivalent, and the typed version is the one to learn, because it can
be written down, checked and repeated for twenty machines. First the machine itself:

```
ana@host:~$ VBoxManage createvm --name lab1 --ostype Ubuntu_64 --register
Virtual machine 'lab1' is created and registered.
UUID: 73b2f8cf-1d72-4905-a30f-6b83ef141c71
Settings file: '/home/ana/VirtualBox VMs/lab1/lab1.vbox'
ana@host:~$ VBoxManage list ostypes | grep -c "^ID:"
188
```

`createvm` makes an empty machine, `--register` adds it to VirtualBox's list, and the answer says where
its settings live. `--ostype Ubuntu_64` is one of **188** types VirtualBox knows. The type sets
sensible defaults for the rest, and it matters more than it looks: VirtualBox picks the network card,
the disk controller and the clock for each type, and a 64-bit system made with a 32-bit type
cannot even start its installer.

Then its hardware:

```
ana@host:~$ VBoxManage modifyvm lab1 --memory 2048 --cpus 2 --graphicscontroller vmsvga --vram 16 --nic1 nat --audio-driver none
```

`modifyvm` changes a machine that is switched off, and prints nothing when it works. This gave it
**2048 MB of memory**, **2 processors**, the **VMSVGA** graphics card with 16 MB of video memory, a
network card on **NAT**, lesson 11, and no sound card, which a lab does not need.
