---
title: What the host knows about a guest
version: 1
---

The host knows everything about a guest's hardware, because it made that hardware up. `virsh dominfo`
is the summary:

```
ana@host:~$ virsh dominfo vm1
Id:             3
Name:           vm1
UUID:           5a98d7b8-1dda-4933-a865-34b0d2c48c15
OS Type:        hvm
State:          running
CPU(s):         2
CPU time:       197.4s
Max memory:     1048576 KiB
Used memory:    1048576 KiB
Persistent:     yes
Autostart:      disable
Managed save:   no
Security model: none
Security DOI:   0
```

`State: running`, `CPU(s): 2` and `Max memory: 1048576 KiB`, exactly the 1 GiB it was given. `CPU time:
197.4s` is how much processor time the guest has used since it started, most of it booting under
imitation. The `UUID` is the guest's identity inside libvirt, and it stays the same however the guest
is renamed. `Persistent: yes` means libvirt keeps the description after the guest stops; `Autostart:
disable` means it does not start with the host.

That description is an XML file, and `virsh dumpxml` prints it. A few of its lines:

```
ana@host:~$ virsh dumpxml vm1 | grep -E "<(memory|vcpu|type|emulator|source file|mac address|model type|target dev)"
  <memory unit='KiB'>1048576</memory>
  <vcpu placement='static'>2</vcpu>
    <type arch='x86_64' machine='pc-q35-noble'>hvm</type>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
      <source file='/var/lib/libvirt/images/vm1.qcow2' index='2'/>
        <source file='/var/lib/libvirt/images/lab-base.qcow2'/>
      <target dev='vda' bus='virtio'/>
      <mac address='52:54:00:ce:da:4e'/>
      <target dev='vnet2'/>
      <model type='virtio'/>
```

Everything the guest will believe about its hardware is written here. **`<memory>` and `<vcpu>`** are
what `free` and `lscpu` report inside. **`<type ... machine='pc-q35-noble'>`** is the model of
motherboard QEMU imitates. **`<emulator>`** is the program that runs it. The disk is `vm1.qcow2`, with
`lab-base.qcow2` under it as its backing file, shown to the guest as `vda` on a `virtio` bus. And the
network card has a MAC address, `52:54:00:ce:da:4e`, chosen by libvirt when the guest was made.

To change a guest's hardware, you change this description, with `virsh edit` or with a graphical tool,
and the guest sees the change the next time it is shut down and started again. Lesson 8 does it to memory and processors.
