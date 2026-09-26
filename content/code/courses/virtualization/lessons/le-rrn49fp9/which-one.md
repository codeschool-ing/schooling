---
title: Which one for which job
version: 1
---

The two are not rivals, and most real systems use both. What decides is what the job needs:

| the job needs | use |
|---|---|
| another operating system, or Windows on a Linux host | a virtual machine |
| to practise installing, booting, disks, kernels | a virtual machine |
| to run something you do not trust | a virtual machine |
| a whole machine to administer, as in this track | a virtual machine |
| to package one application with everything it needs | a container |
| many copies of a service that start and stop quickly | a container |
| the same tools on every developer's computer | a container |

And the layers stack. Clouds rent virtual machines, and most of what runs in them runs in containers.
The computer this course was recorded on is an example of both at once:

```
ana@host:~$ systemd-detect-virt --container; systemd-detect-virt --vm
systemd-nspawn
kvm
```

The course's host is **a container**, made with `systemd-nspawn`, **inside a virtual machine** running
under KVM in a data centre, and the virtual machines of this course run inside that. Each layer answers a
different question: the data centre's virtual machine gives a whole computer to rent, the container keeps
the lab separate from the tools that record it, and the lab's guests are the computers this course is
about.
