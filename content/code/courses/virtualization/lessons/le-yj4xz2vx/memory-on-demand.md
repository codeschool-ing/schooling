---
title: Memory on demand, and the balloon
version: 1
---

A guest's memory is taken from the host **when the guest first touches it**, not when the guest starts.
Here the guest uses 400 MB for a moment and lets it go:

```
ana@host:~$ sudo pmap -x $(pgrep -o qemu-system) | awk "\$2 == 1048576"
00007fa383e00000 1048576  446464  446464 rw---   [ anon ]
ana@vm1:~$ python3 -c "b = b\"x\" * (400 * 1024 * 1024)"; free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:             961         277         627           0         203         683
ana@host:~$ sudo pmap -x $(pgrep -o qemu-system) | awk "\$2 == 1048576"
00007fa383e00000 1048576  804864  804864 rw---   [ anon ]
```

Before, 446464 KiB of the guest's memory area was resident on the host; after, 804864 KiB. Inside, the
program has finished and `free` shows the memory free again, but **the host does not get it back**: to
the host, a page the guest has touched is a page in use, whatever the guest did with it afterwards.

That is why a host can start guests whose memory adds up to more than it has, which is called
**overcommitting**, and why it works until the day they all get busy. Then the host runs short, starts
swapping, and in the end kills a process to survive, and the process it picks is usually the largest:
a guest.

The **balloon** is the way to take memory back from a running guest. A small driver in the guest,
`virtio_balloon`, allocates memory inside the guest when the host asks, so the guest's own system stops
using it, and hands those pages back:

```
ana@host:~$ virsh setmem vm1 524288 --live

ana@vm1:~$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:             449         231         161           0         204         217
ana@host:~$ virsh dommemstat vm1 | grep -E "^(actual|rss)"
actual 524288
rss 1548340
ana@host:~$ virsh setmem vm1 1048576 --live

ana@vm1:~$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:             961         247         657           0         204         713
```

With the balloon inflated to leave 512 MiB, the guest's `free` shows 449 MiB total, and the
process's `rss` is 1548340 KiB, lower than it was before the guest touched its 400 MB. Deflated again,
the guest has 961 MiB. It is a blunt tool: a guest squeezed below what its programs use starts
swapping, or kills something itself. It is how Proxmox and ESXi move memory between guests on a busy
host, and why a guest's memory in their interfaces can move without anybody editing it.
