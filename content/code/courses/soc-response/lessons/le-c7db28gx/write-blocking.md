---
title: Write blocking
version: 1
---

Connecting a disk to a computer is enough to change it. An operating system that sees a file system may mount
it, replay its journal, update an access time; any of those writes to the evidence, and the hash taken
afterwards no longer matches the one anybody else will take. A **write blocker** sits between the disk and the
examiner's computer and **passes reads and refuses writes**. In a real case it is a small hardware device
between the disk's cable and the computer; hardware is preferred because it does not depend on the examiner's
operating system behaving.

In the lab, Linux itself plays the part. `losetup` presents `disk.img` as a block device, and `--read-only`
makes the kernel refuse every write to it:

```
root@soc:~/case# losetup --read-only --find --show disk.img
/dev/loop0
root@soc:~/case# blockdev --getro /dev/loop0
1
root@soc:~/case# dd if=/dev/zero of=/dev/loop0 count=1
dd: writing to '/dev/loop0': Operation not permitted
1+0 records in
0+0 records out
0 bytes copied, 2.3043e-05 s, 0.0 kB/s
```

`losetup` answers with the device it chose, `/dev/loop0`; on your machine it may be another number, so use the
one it prints. `blockdev --getro` reads the device's read-only flag: `1`. And the proof is the last command,
which tries to write one block of zeros to the device and is refused: `Operation not permitted`, with `0 bytes`
written. **Test the blocker before trusting it**, every time, the way lesson 13 tested a firewall rule. A write
blocker that silently passes writes is worse than none, because everybody believes it.
