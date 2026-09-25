---
title: Changing a guest
version: 1
---

Most of a guest's hardware is fixed while it runs, and is changed in its description for the next
start. Here vm1 goes down to one vCPU and gets the disk setting of section 06:

```
ana@host:~$ virsh setvcpus vm1 1 --config && virsh vcpucount vm1

maximum      config         2
maximum      live           2
current      config         1
current      live           2

ana@host:~$ virt-xml vm1 --edit target=vda --disk driver.discard=unmap
Domain 'vm1' defined successfully.
Changes will take effect after the domain is fully powered off.
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ virsh start vm1
Domain 'vm1' started

ana@vm1:~$ nproc
1
```

`--config` changed the description and left the running guest alone, which is why `vcpucount` shows
`current config 1` next to `current live 2`. `virt-xml` edited the disk and said so plainly: **Changes
will take effect after the domain is fully powered off**. *Fully*: a reboot from inside the guest keeps
the same QEMU process running, and the process is what holds the old hardware. After a real shutdown
and start, `nproc` inside says 1.

The same rule holds in every hypervisor, with different words. VirtualBox greys out most settings while
a machine runs. VMware and Proxmox accept some changes live, such as adding memory or processors to a
guest that supports it, and mark the rest as pending until the next *power off*. When a customer says
"I changed it and nothing happened", the first question is whether the machine has been **switched off
and on**, not restarted.
