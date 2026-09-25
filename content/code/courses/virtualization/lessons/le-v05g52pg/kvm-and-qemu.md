---
title: KVM, and why the labels blur
version: 1
---

The lab in this course uses **QEMU** and **KVM**, and they fit neither box neatly, which is worth
knowing because you will meet the argument.

**QEMU** on its own is a type 2 hypervisor in the purest sense: an ordinary program that imitates a
whole computer, processor included, in software. It can imitate a processor it does not even have,
an ARM on an Intel laptop, for instance. It is correct and slow.

**KVM** is part of the Linux kernel. Loaded, it turns Linux itself into a hypervisor: the kernel
schedules guests the way it schedules processes, and uses the processor's virtualisation features to
run their instructions directly. QEMU then only supplies the devices, the disk and the network card,
and hands the processor to KVM. Is Linux with KVM type 1, because the hypervisor is in the kernel on
the hardware, or type 2, because it is an ordinary system you also use for other things? People who
know what they are talking about disagree, and Proxmox, lesson 6, is built on it.

**Keep the question, not the label: what is closest to the hardware, and does the processor help?**
The second half of that question turns out to matter much more for speed, and it is where this
course's own lab has something to show.
