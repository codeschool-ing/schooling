---
title: Mounting: a disk arrives as a directory
version: 3
---

Lesson 1 section 10 said it: there are no drive letters, there is one tree, and every disk appears
somewhere inside it. The verb for *appears somewhere inside it* is **mount**, and this section is
what that actually looks like.

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G  9.6G   30G  25% /
```

Read the two ends together. `/dev/vda` is a **device** — an entry in `/dev`, a disk. `/` is the
**mount point** — a directory in the tree. Mounting is the act of connecting those two, and from
that moment, opening that directory opens that disk.

## Seeing what is mounted

Three commands, increasingly specific:

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G  9.6G   30G  25% /
```

`df` — *disk free* — is the one you will type. It takes a path and answers about the filesystem
that path lives on, which is the useful question. With no argument it lists everything.

```
ana@vm:~$ findmnt -no SOURCE,FSTYPE /
/dev/vda ext4
```

`findmnt` is the precise one: what is mounted where, with what type and what options. `-n` drops
the header, `-o` picks the columns.

```
ana@vm:~$ lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS /dev/vda
NAME  SIZE TYPE MOUNTPOINTS
vda   256G disk /
```

`lsblk` lists **block devices** — the hardware side — whether or not they are mounted. That last
part is what makes it the right tool when a disk is *missing*: `df` cannot show you a disk that is
not mounted, and `lsblk` can. With no arguments it lists every device on the machine; here it was
given one.

This machine is a virtual one, which is why its disk is `vda`. On a laptop you would see `sda` or
`nvme0n1` with two or three `part` rows under it — the partitions — and mount points beside them.

**Device names are not promises.** `vda` on a virtual machine, `sda` on something with SATA,
`nvme0n1p2` on a modern laptop, and the letters are assigned in the order the kernel found the
disks. That is why `/etc/fstab` prefers a UUID, below.

## What mounting actually does to a directory

To try this you need a second disk, and a file can stand in for one. Mounting needs root, so the
rest of this section works in a root shell: `sudo -i` opens one, its prompt ends in `#`, and lesson
4 is about what that means. Then make a directory to mount on, a 64 MB file of zeros, and an empty
filesystem inside the file, labelled `backups`:

```
ana@vm:~$ sudo -i
root@vm:~# mkdir -p /root/img /mnt/backups
root@vm:~# dd if=/dev/zero of=/root/img/disk.img bs=1M count=64 status=none
root@vm:~# mkfs.ext4 -q -L backups /root/img/disk.img
```

Here is the whole idea in one session. A directory, with something in it:

```
root@vm:~# echo 'this is on the main disk' > /mnt/backups/oops.txt
root@vm:~# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G  9.6G   30G  25% /
```

Nothing is mounted there yet, so `/mnt/backups` is an ordinary directory on the main disk. Now
mount something onto it:

```
root@vm:~# mount -o loop /root/img/disk.img /mnt/backups
root@vm:~# ls -la /mnt/backups
total 24
drwxr-xr-x 3 root root  4096 Oct  7 11:10 .
drwxr-xr-x 7 root root  4096 Oct  7 11:10 ..
drwx------ 2 root root 16384 Oct  7 11:10 lost+found
root@vm:~# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   24K   52M   1% /mnt/backups
```

**`oops.txt` is gone.** Not deleted — *covered*. The directory now shows the contents of the
mounted filesystem, and the same path answers to a different disk. `df` proves it: 56 MB where a
moment ago there were 252 GB.

Work in it normally:

```
root@vm:~# mkdir /mnt/backups/nightly
root@vm:~# touch /mnt/backups/nightly/2026-09-14.tar.gz
root@vm:~# ls -R /mnt/backups
/mnt/backups:
lost+found
nightly

/mnt/backups/lost+found:

/mnt/backups/nightly:
2026-09-14.tar.gz
```

And unmount:

```
root@vm:~# umount /mnt/backups
root@vm:~# ls -la /mnt/backups
total 12
drwxr-xr-x 2 root root 4096 Oct  7 11:10 .
drwxr-xr-x 7 root root 4096 Oct  7 11:10 ..
-rw-r--r-- 1 root root   25 Oct  7 11:10 oops.txt
root@vm:~# cat /mnt/backups/oops.txt
this is on the main disk
```

`oops.txt` is back, untouched, and `nightly/` is not — it is on the other disk, waiting to be
mounted again.

**Three things to take from that**, and the third is the one that costs money.

The command is `umount`, **not** `unmount`. Everybody types it wrong once.

A mount point does not have to be empty, and mounting does not warn you that it is not.

And the expensive one: **a backup job writing to `/mnt/backups` when nothing is mounted there
writes happily to the main disk.** No error. It even looks like it worked — there are files, in
the right place, with the right names. It is discovered months later, usually on the day somebody
needs the backup. Lesson 11 comes back to this; the defence is to check `findmnt /mnt/backups`
before writing, and to make the unmounted directory unwritable so the job fails loudly instead of
quietly.

## `mount` and `umount` need root, and take two forms

```
sudo mount /dev/sdb1 /mnt/data          # this device, on this directory
sudo umount /mnt/data                   # or: umount /dev/sdb1
```

`-o` passes options — `ro` for read-only, `loop` to mount a *file* as if it were a disk, which is
how the demo above worked and how you mount an ISO image.

The error you will actually hit is this one:

```
root@vm:~# mount -o loop /root/img/disk.img /mnt/backups
root@vm:~# cd /mnt/backups
root@vm:/mnt/backups# umount /mnt/backups
umount: /mnt/backups: target is busy.
root@vm:/mnt/backups# cd /
root@vm:/# umount /mnt/backups
root@vm:/# echo $?
0
```

Something has a file open there, or somebody's shell is sitting inside it — and look at the prompt
in that transcript, because **the somebody was me**. A shell whose working directory is on a
filesystem is using that filesystem. `cd` out and the unmount succeeds.

When it is not you, `lsof +D /mnt/data` or `fuser -vm /mnt/data` names the culprit, and lesson 6 is
where those become familiar.

## `/etc/fstab` is the list of what to mount at boot

```
root@vm:~# cat /etc/fstab
# UNCONFIGURED FSTAB FOR BASE SYSTEM
```

Empty, on the machine these transcripts were captured on, because its root filesystem was mounted
by the thing that started it rather than from a table. On the machine you installed in lesson 1 it
has a line for each filesystem the installer made. On a normal installation it has a line per
filesystem, six fields each:

| field | is | example |
|---|---|---|
| 1 | what to mount | `UUID=2f1a-…` |
| 2 | where | `/home` |
| 3 | type | `ext4` |
| 4 | options | `defaults,noatime` |
| 5 | dump | `0` — an obsolete backup flag, always `0` |
| 6 | fsck order | `1` for root, `2` for others, `0` to skip |

**Field 1 is usually a UUID rather than `/dev/sdb1`**, and that is the important detail: device
letters change when you add a disk, and a UUID belongs to the filesystem itself. `blkid` prints
them, and it reads a filesystem in a file as happily as one on a disk:

```
root@vm:~# blkid /root/img/disk.img
/root/img/disk.img: LABEL="backups" UUID="00826b00-4138-4b93-9ff5-ced97fdda026" BLOCK_SIZE="4096" TYPE="ext4"
```

That UUID was written into the filesystem when it was created and travels with it — into another
slot, another machine, another cable order. A machine that will not boot after somebody added a
second drive is nearly always a machine whose `fstab` named a letter.

**Editing `/etc/fstab` wrong can stop a machine from booting**, so the ritual is: edit it, then run
`sudo mount -a` — which mounts everything in the file that is not already mounted — and confirm it
is silent *before* you reboot. `mount -a` is the free rehearsal.

## Where you will meet mounts without setting one up

| | |
|---|---|
| a USB stick | appears at `/media/ana/LABEL`, mounted for you by the desktop |
| an ISO image | `mount -o loop image.iso /mnt/iso` |
| a network share | NFS or SMB, mounted at whatever directory you choose |
| Windows, inside WSL | `/mnt/c` — the same mechanism, and why it is slower |
| a container | its whole filesystem is mounts, and `-v` on `docker run` adds one |
| `/proc`, `/sys`, `/dev` | mounted, and not on any disk at all — section 14 |

When you are done, `exit` leaves the root shell, and the prompt is yours again.
