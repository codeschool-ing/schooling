---
title: Devices made for guests
version: 1
---

A hypervisor can give a guest two kinds of device. It can **imitate a real one**, an Intel network card
or an old IDE disk controller, which every operating system already has a driver for, at the cost of
imitating every register of hardware that was never designed to be imitated. Or it can offer a device
**designed for guests**, which does the same job in far fewer steps and needs a driver that knows it.
On QEMU the second kind is called **virtio**, and a Linux guest has the drivers already:

```
ana@vm1:~$ ls /sys/bus/virtio/drivers
virtio_balloon
virtio_blk
virtio_console
virtio_iommu
virtio_net
virtio_rng
virtio_rproc_serial
virtio_scsi
```

`virtio_blk` is vm1's disk, `virtio_net` its network card, `virtio_balloon` the balloon of section 04,
`virtio_console` the agent's channel, and `virtio_rng` a source of random numbers from the host. A
Linux guest on QEMU uses them without being asked.

A **Windows guest does not**: Windows has no virtio drivers of its own. Installing Windows on a virtio
disk shows an installer that finds no disk at all, until the drivers are loaded from the *virtio-win*
ISO with *Load driver*. The alternative is to give it an imitated SATA disk and an Intel network card,
which work at once and are slower. Every hypervisor has its own designed devices with the same trade:
VMware's are VMXNET3 and PVSCSI, installed with VMware Tools; Hyper-V's come with its Integration
Services.
