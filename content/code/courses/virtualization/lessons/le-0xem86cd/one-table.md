---
title: One table for all of them
version: 1
---

Every hypervisor in this course has the same parts under different names. This is the table to keep
open during a call about a product you have not used:

| | libvirt and QEMU | VirtualBox | VMware Workstation | ESXi | Hyper-V | Proxmox |
|---|---|---|---|---|---|---|
| type | argued | 2 | 2 | 1 | 1 | argued, as libvirt |
| settings | XML | `.vbox` | `.vmx` | `.vmx` | `.vmcx` | `100.conf` |
| disk | qcow2 | VDI | VMDK | VMDK | VHDX | qcow2, or LVM and ZFS volumes |
| agent | qemu-guest-agent | Guest Additions | VMware Tools | VMware Tools | Integration Services | qemu-guest-agent |
| saving a state | snapshot | snapshot | snapshot | snapshot | checkpoint | snapshot |
| the guests' switch | virbr0 | per network mode | VMnet0, 1, 8 | vSwitch | virtual switch | vmbr0 |
| managed from | virsh, virt-manager | its window, VBoxManage | its window, vmrun | Host Client, vCenter | Hyper-V Manager, PowerShell | a browser, qm |

The rows that matter most for support are **disk** and **agent**. A disk can always be carried to
another hypervisor and converted, lesson 5. A guest without its agent is the cause of a great many
small complaints: a screen that will not resize, a clipboard that does nothing, a shutdown
that has to be forced, an address the host cannot show.

**Lessons 8 to 15 use libvirt for everything**, because it is what the lab can run. Each thing they do
exists in every column of this table, under the name in its row.
