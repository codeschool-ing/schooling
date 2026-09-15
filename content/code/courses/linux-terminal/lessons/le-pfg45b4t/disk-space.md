---
title: Disk space, and three ways a full disk is not full
version: 1
---

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  30% /
```

Read that line carefully. **252 gigabytes total, 11 used, 27 available — and
11 plus 27 is not 252.**

That is not a bug and it is the first thing to understand about `df`:

```
ana@vm:~$ stat -f / | head -6
  File: "/"
    ID: 98cd458b5846bde Namelen: 255     Type: ext2/ext3
Block size: 4096       Fundamental block size: 4096
Blocks: Total: 66053021   Free: 63208038   Available: 6867148
Inodes: Total: 16777216   Free: 16553026
```

**`Free` and `Available` are different numbers.** 63 million blocks are unused;
6.8 million of them are available *to you*. The rest is reserved — by default
ext4 keeps 5% for `root` so that a full disk does not stop the machine being
repaired, and on this machine a quota reserves a great deal more than that.

And `Use%` is computed against what you can use, not against the total:
11 / (11 + 27) is 29%, which rounds to the 30% in the output. **`df` is telling
you the truth about a number you did not ask for**, and the moment you need
`Size` to equal `Used + Avail` you have the wrong mental model.

`tune2fs -m 1 /dev/sda1` changes the reserve to 1%, which on a multi-terabyte
data disk recovers a useful amount and on the root filesystem is a bad idea.

## Full with space free

```
ana@vm:/mnt/small$ df -h /mnt/small; df -i /mnt/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       28M   24K   26M   1% /mnt/small
Filesystem     Inodes IUsed IFree IUse% Mounted on
/dev/loop0        256    11   245    5% /mnt/small
ana@vm:/mnt/small$ cd /mnt/small && for i in $(seq 1 300); do touch f$i 2>/dev/null; done; ls | wc -l
246
ana@vm:/mnt/small$ touch one-more
touch: cannot touch 'one-more': No space left on device
ana@vm:/mnt/small$ df -h /mnt/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       28M   24K   26M   1% /mnt/small
ana@vm:/mnt/small$ df -i /mnt/small
Filesystem     Inodes IUsed IFree IUse% Mounted on
/dev/loop0        256   256     0  100% /mnt/small
```

**`No space left on device`, with 26 megabytes free and 1% used.**

That is a filesystem built with 256 inodes, which is a deliberately tiny number
for this demonstration — the `mkfs.ext4 -N 256` is the only unusual thing here.
Every file needs one inode whatever its size, so three hundred empty files ran
out of inodes with the data blocks barely touched.

**`ENOSPC` means "no space" and `df -h` is only half the question.** On a real
machine this is a mail spool, a session directory or a cache of millions of tiny
files, and it is one of the few failures where the error message points at
exactly the wrong number.

`df -i` is the other half, and it costs nothing to look.

## Full with the file deleted

The second way, and the one that wastes the most time:

```
ana@vm:~$ df -h /mnt/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       28M   21M  5.7M  78% /mnt/small
ana@vm:~$ du -sh /mnt/small
du: cannot read directory '/mnt/small/lost+found': Permission denied
20K     /mnt/small
ana@vm:~$ ls -la /mnt/small
total 24
drwxr-xr-x 3 ana  ana   4096 Sep 15 11:28 .
drwxr-xr-x 8 root root  4096 Sep 15 11:27 ..
drwx------ 2 root root 16384 Sep 15 11:27 lost+found
```

**`df` says 21 megabytes are used. `du` says 20 kilobytes. `ls` shows nothing at
all.**

(The `du` warning is unrelated and is honest: `lost+found` is mode 700 owned by
root, so an ordinary user cannot walk it. It is empty.)

The answer:

```
ana@vm:~$ lsof +L1 /mnt/small
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NLINK NODE NAME
sleep   16238  ana    9w   REG    7,0 20971520     0   12 /mnt/small/big.log (deleted)
```

**`NLINK 0` and `(deleted)`.** A process has the file open; somebody deleted the
name; the data cannot be freed until the last descriptor closes. Section 46's
hard links and section 98's descriptors, meeting in the least convenient place.

`lsof +L1` lists open files with fewer than one link — which is exactly this
case and nothing else.

**The fix is not `rm`**, because there is nothing left to remove. It is to
restart the process, or, if you cannot, truncate the file through its
descriptor:

```sh
: > /proc/16238/fd/9        # the space comes back immediately
```

This is what happens when somebody rotates a log by deleting it instead of by
`logrotate`: the disk stays full until the service is restarted, and `du` swears
the space is not being used.

## Finding the space

```sh
du -sh /*                     # which top-level directory
du -h --max-depth=1 /var | sort -h    # then walk down
du -xh --max-depth=1 /        # -x stays on one filesystem
find / -xdev -size +1G -type f 2>/dev/null   # the few big ones
ncdu /var                     # interactive, if it is installed
```

**`-x` is the flag people forget.** Without it, `du /` walks into every mounted
filesystem, including network mounts, and you wait a long time for an answer
about a disk you were not asking about.

And `du` reports **blocks used**, not bytes in the file — so a sparse file
reports small, and a thousand one-byte files report four megabytes. `du
--apparent-size` gives the other number, and the difference between them is
usually the more interesting fact.

## Three checks, in order

| | |
|---|---|
| `df -h` | is the data area full |
| `df -i` | are the inodes full |
| `lsof +L1` | is it held open by something, deleted |

**Run all three before you start deleting anything.** The third one especially:
deleting more files to free space on a filesystem whose space is held by an
already-deleted file achieves nothing at all, and it is very easy to spend
twenty minutes proving that.
