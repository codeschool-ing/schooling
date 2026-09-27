---
title: Ruling out the network and the hardware
version: 1
---

A cause has been found, and two layers have not been looked at. Two commands close them:

```
ana@pc1:~$ findmnt -o TARGET,SOURCE,FSTYPE /srv/shared
TARGET      SOURCE     FSTYPE
/srv/shared /dev/loop0 ext4
ana@pc1:~$ sudo dmesg --level=err,crit,alert,emerg | wc -l
0
```

- **Network**: `findmnt` says where `/srv/shared` comes from. Its source is a local device, not a server
  on the network, so nothing in this path crosses a cable. Had it said `nfs` or `cifs`, the folder
  would live on another machine, and a full disk would be *that* machine's problem to report.
- **Hardware**: `dmesg` holds the kernel's messages, and asked only for errors and worse it returns
  **0** lines. A failing disk usually complains there first, in words like `I/O error`.

Checking the layers that are fine is not wasted work. It is what lets the ticket say *the disk is full*
rather than *the disk is full, probably*, and it is what the next technician will want to see before
trusting it.
