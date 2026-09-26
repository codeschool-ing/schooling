---
title: What the lab costs, and keeping it
version: 1
---

Three guests running at once, and what the host pays for them:

```
ana@host:~$ virsh list --all; free -h | head -2
 Id   Name     State
------------------------
 1    client   running
 2    server   running
 4    target   running

               total        used        free      shared  buff/cache   available
Mem:            15Gi       4.3Gi       9.7Gi        13Mi       1.9Gi        11Gi
ana@host:~$ ps -o rss= -C qemu-system-x86_64 | awk "{ s += \$1 } END { print s, \"KiB for\", NR, \"guests\" }"
3933004 KiB for 3 guests
ana@host:~$ for m in client server target; do virsh shutdown $m; done
Domain 'client' is being shutdown

Domain 'server' is being shutdown

Domain 'target' is being shutdown

ana@host:~$ virsh list --all; virsh snapshot-list target
 Id   Name     State
-------------------------
 -    client   shut off
 -    server   shut off
 -    target   shut off

 Name     Creation Time               State
-----------------------------------------------
 broken   2026-09-25 22:46:28 -0300   running
```

**3933004 KiB for three guests**, about 3.8 GiB, on a host with 15Gi. On this computer most of each
guest's cost is the imitated processor, lesson 8; with KVM, three small guests cost a good deal less.
Either way the rule of lesson 1 holds: switch off what you are not using. The three were shut down, and
the snapshots survive a shutdown, so the next practice starts from `broken` whenever it comes.

Two habits keep a lab useful for a long time:

- **Keep the recipe, not only the machines.** Everything in this lesson is a handful of commands, and
  written down in a script they rebuild the lab in minutes on any computer. This course's own lab is
  exactly that, `lab.sh`.
- **One lab per purpose.** A lab that is also somebody's test server collects changes nobody remembers,
  and the day it is reverted, somebody's work goes with it.
