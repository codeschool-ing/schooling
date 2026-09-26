---
title: Switch it off, break it, throw it away
version: 1
---

A guest is switched off and on from the host, as if somebody pressed its power button:

```
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ virsh list --all
 Id   Name   State
-----------------------
 -    vm1    shut off

ana@host:~$ virsh start vm1
Domain 'vm1' started

ana@vm1:~$ uptime -p
up 1 minute
```

`virsh shutdown` does not stop the process. It **asks the guest to shut down**, the same signal a
real computer gets from a short press of the power button, and Ubuntu inside closes its services and
powers off by itself. Thirty seconds later the guest is `shut off`: no process, no memory used, and a
file on the disk. `virsh start` boots it again from that file, and `uptime` inside says it has been
`up 1 minute`. Everything it had on its disk is still there.

Now the thing you cannot do on a computer you care about. Inside the guest, ana deletes everything,
from the root down:

```
ana@vm1:~$ sudo rm -rf --no-preserve-root / 2>/dev/null; ls /
bash: line 1: ls: command not found
ana@host:~$ virsh destroy vm1 && virsh undefine vm1 && sudo rm /var/lib/libvirt/images/vm1.qcow2
Domain 'vm1' destroyed

Domain 'vm1' has been undefined

ana@host:~$ virsh list --all
 Id   Name   State
--------------------
```

`ls` is gone, and so is everything else; the guest is still running, with nothing left to run. On a
real computer this is a reinstall and a lost afternoon. Here it is one line on the host.
`virsh destroy` is the opposite of `shutdown`: it **pulls the plug**, which is fine for a machine
about to be deleted and a bad habit for one that is not. `virsh undefine` removes libvirt's
description of it, and `rm` removes the file. The list is empty.

The base disk was never touched, because every write went to `vm1.qcow2`. The next guest in this
course is made from the same base in a minute, as if nothing had happened.
