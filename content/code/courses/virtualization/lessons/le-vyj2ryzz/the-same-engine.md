---
title: The same engine
version: 1
---

Whatever manages it, a QEMU guest ends up as one long command line: libvirt writes one for `virsh`,
and Proxmox writes one for `qm`. Here is the lab's, for vm1, with the options that describe the
hardware picked out, one per line:

```
ana@host:~$ tr "\0" "\n" < /proc/$(pgrep -o qemu-system)/cmdline | awk "/^-(name|machine|accel|m|smp|blockdev|netdev|device)\$/ { o = \$0; getline; if (\$0 !~ /pcie-root-port/) print o, \$0 }"
-name guest=vm1,debug-threads=on
-machine pc-q35-noble,usb=off,dump-guest-core=off,memory-backend=pc.ram,hpet=off,acpi=on
-accel tcg
-m size=1048576k
-smp 2,sockets=2,cores=1,threads=1
-device {"driver":"qemu-xhci","p2":15,"p3":15,"id":"usb","bus":"pci.2","addr":"0x0"}
-device {"driver":"virtio-serial-pci","id":"virtio-serial0","bus":"pci.3","addr":"0x0"}
-blockdev {"driver":"file","filename":"/var/lib/libvirt/images/lab-base.qcow2","node-name":"libvirt-3-storage","auto-read-only":true,"discard":"unmap"}
-blockdev {"node-name":"libvirt-3-format","read-only":true,"driver":"qcow2","file":"libvirt-3-storage","backing":null}
-blockdev {"driver":"file","filename":"/var/lib/libvirt/images/vm1.qcow2","node-name":"libvirt-2-storage","auto-read-only":true,"discard":"unmap"}
-blockdev {"node-name":"libvirt-2-format","read-only":false,"driver":"qcow2","file":"libvirt-2-storage","backing":"libvirt-3-format"}
-device {"driver":"virtio-blk-pci","bus":"pci.4","addr":"0x0","drive":"libvirt-2-format","id":"virtio-disk0","bootindex":1}
-blockdev {"driver":"file","filename":"/var/lib/libvirt/images/vm1-seed.img","node-name":"libvirt-1-storage","auto-read-only":true,"discard":"unmap"}
-blockdev {"node-name":"libvirt-1-format","read-only":false,"driver":"raw","file":"libvirt-1-storage"}
-device {"driver":"virtio-blk-pci","bus":"pci.5","addr":"0x0","drive":"libvirt-1-format","id":"virtio-disk1"}
-netdev {"type":"tap","fd":"31","id":"hostnet0"}
-device {"driver":"virtio-net-pci","netdev":"hostnet0","id":"net0","mac":"52:54:00:17:24:6d","bus":"pci.1","addr":"0x0"}
-device {"driver":"isa-serial","chardev":"charserial0","id":"serial0","index":0}
-device {"driver":"virtserialport","bus":"virtio-serial0.0","nr":1,"chardev":"charchannel0","id":"channel0","name":"org.qemu.guest_agent.0"}
-device {"driver":"virtio-balloon-pci","id":"balloon0","bus":"pci.6","addr":"0x0"}
-device {"driver":"virtio-rng-pci","rng":"objrng0","id":"rng0","bus":"pci.7","addr":"0x0"}
```

Read top to bottom, it is lesson 3's XML in QEMU's own words. **`-accel tcg`** is the software
processor of lesson 2; on a Proxmox server it says `kvm`. **`-m size=1048576k`** and **`-smp 2`** are
the memory and processors. The **`-blockdev`** lines come in pairs, a file and a format, and the second
pair names the first as its `backing`: that is the overlay on the base disk from lesson 1. The
`virtio-net-pci` card has the MAC `52:54:00:17:24:6d`, the `virtserialport` named `org.qemu.guest_agent.0` is the
agent's channel from lesson 3, and the `virtio-balloon-pci` device comes back in lesson 8.

On a Proxmox server, `qm showcmd 100 --pretty` prints the same kind of line for machine 100. You
will rarely need it, but when a machine will not start and the web interface only says the start
failed, **the command line and the error QEMU printed are the facts**, and every manager can show you
both.
