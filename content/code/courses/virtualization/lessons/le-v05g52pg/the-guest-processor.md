---
title: The processor QEMU imitates
version: 1
---

Inside the guest, the same two questions:

```
ana@vm1:~$ lscpu | grep -E "^(Vendor ID|Model name|Virtualization|Hypervisor)"
Vendor ID:                               AuthenticAMD
Model name:                              QEMU Virtual CPU version 2.5+
Virtualization:                          AMD-V
ana@vm1:~$ grep -m1 "^flags" /proc/cpuinfo | grep -owE "vmx|svm|hypervisor"
hypervisor
svm
```

The imitated processor calls itself `AuthenticAMD`, the name AMD's processors give, with the model
`QEMU Virtual CPU version 2.5+`. It has the `hypervisor` flag, so the guest's own software knows it is
a guest. It even lists `svm`, and `lscpu` reports `AMD-V`: QEMU copies the flags of the processor it
is imitating, and running guests inside a guest is something this course leaves alone.

What `lscpu` does not print is a `Hypervisor vendor` line. The flag says "you are a guest"; the
vendor line needs the hypervisor to say its name as well, and QEMU's software processor does not.
Compare the host's processor above, where KVM does.

**Flags are claims that a processor makes about itself**, and a guest's processor claims whatever its
hypervisor decides. Read them on the host to know what the real processor offers, and in a guest to
know what that guest was given.
