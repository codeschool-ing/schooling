---
title: When the processor helps
version: 1
---

A guest's operating system expects to be in charge of the processor. It wants to switch memory maps,
handle interrupts and talk to devices, and a guest must not be allowed to do any of that for real, or
it would be in charge of the host. Without help, a hypervisor has to catch or translate every such
instruction in software. **VT-x** on Intel processors and **AMD-V** on AMD ones add a mode made for
guests: the processor runs the guest's instructions directly and stops only on the ones the
hypervisor has to see. Linux shows them as the flags **`vmx`** and **`svm`** in `/proc/cpuinfo`.

Here is what the course's host has:

```
ana@host:~$ lscpu | grep -E "^(Vendor ID|Model name|Virtualization|Hypervisor)"
Vendor ID:                               GenuineIntel
Model name:                              Intel(R) Xeon(R) Processor @ 2.10GHz
Hypervisor vendor:                       KVM
Virtualization type:                     full
ana@host:~$ grep -m1 "^flags" /proc/cpuinfo | grep -owE "vmx|svm|hypervisor"
hypervisor
ana@host:~$ systemd-detect-virt --vm
kvm
```

The first line of flags has `hypervisor` and neither `vmx` nor `svm`. The **`hypervisor` flag means
this processor is itself a guest's**, and `lscpu` names who is running it, `KVM`, as does
`systemd-detect-virt --vm`. The computer this course was recorded on is a virtual machine in a data
centre, and whoever runs that data centre does not pass VT-x on to its guests.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Where this course was recorded, as layers. At the bottom, a data centre&#x27;s hardware, whose processor has VT-x. On it, KVM, the hypervisor that runs host, and the processor helps at this layer. On KVM, host itself, running Ubuntu, which is a guest. On host, QEMU, imitating a processor in software, because no vmx flag reached host, so the processor does not help at this layer. On QEMU, vm1.\"><defs><marker id=\"ns-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vm1</text><rect x=\"20\" y=\"60\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">QEMU, imitating a processor in software</text><rect x=\"20\" y=\"106\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">host: Ubuntu, a guest itself</text><rect x=\"20\" y=\"152\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">KVM, the hypervisor that runs host</text><rect x=\"20\" y=\"198\" width=\"400\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a data centre’s hardware, with VT-x</text><path d=\"M440 170 L470 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"480\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the processor helps here</text><path d=\"M440 78 L470 78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"480\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">and not here: no vmx reached host</text></svg>", "caption": "The course’s host is a guest of somebody else’s KVM, and the processor’s help stops at that layer. So host’s own guests run on a processor that QEMU imitates, which is what the rest of this lesson measures."}
```

So KVM cannot work on host, and each layer says so in its own words:

```
ana@host:~$ ls -l /dev/kvm
crw-rw-r-- 1 root kvm 10, 232 Sep 25 18:00 /dev/kvm
ana@host:~$ sudo qemu-system-x86_64 -accel kvm -machine none -display none
Could not access KVM kernel module: No such device
qemu-system-x86_64: -accel kvm: failed to initialize kvm: No such device
ana@host:~$ virsh domcapabilities --virttype kvm
error: failed to get emulator capabilities
error: invalid argument: the accel 'kvm' is not supported by '/usr/bin/qemu-system-x86_64' on this host

ana@host:~$ virsh capabilities | grep "domain type"
      <domain type='qemu'/>
      <domain type='qemu'/>
```

`/dev/kvm` is there, but the kernel behind it has nothing to offer, `No such device`. `virsh
domcapabilities` for `kvm` is refused, and the capabilities libvirt lists offer only `domain
type='qemu'`, once for 32-bit and once for 64-bit guests. That is why every guest in this course is made
with `--virt-type qemu`.
