---
title: Mounting: a disk arrives as a directory
version: 1
---

Lesson 1 section 10 said it: there are no drive letters, there is one tree, and every disk appears
somewhere inside it. The verb for *appears somewhere inside it* is **mount**, and this section is
what that actually looks like.

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
```

Read the two ends together. `/dev/vda` is a **device** — an entry in `/dev`, a disk. `/` is the
**mount point** — a directory in the tree. Mounting is the act of connecting those two, and from
that moment, opening that directory opens that disk.

## Seeing what is mounted

Three commands, increasingly specific:

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
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
root@vm:/root# lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS /dev/vda /dev/loop0
NAME   SIZE TYPE MOUNTPOINTS
loop0   64M loop /mnt/backups
vda    256G disk /
```

`lsblk` lists **block devices** — the hardware side — whether or not they are mounted. That last
part is what makes it the right tool when a disk is *missing*: `df` cannot show you a disk that is
not mounted, and `lsblk` can. With no arguments it lists every device on the machine; here it was
given two.

This machine is a virtual one, which is why its disk is `vda`. On a laptop you would see `sda` or
`nvme0n1` with two or three `part` rows under it — the partitions — and mount points beside them.

**Device names are not promises.** `vda` on a virtual machine, `sda` on something with SATA,
`nvme0n1p2` on a modern laptop, and the letters are assigned in the order the kernel found the
disks. That is why `/etc/fstab` prefers a UUID, below.

## What mounting actually does to a directory

Here is the whole idea in one session. A directory, with something in it:

```
root@vm:/root# echo 'this is on the main disk' > /mnt/backups/oops.txt
root@vm:/root# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
```

Nothing is mounted there yet, so `/mnt/backups` is an ordinary directory on the main disk. Now
mount something onto it:

```
root@vm:/root# mount -o loop /root/img/disk.img /mnt/backups
root@vm:/root# ls -la /mnt/backups
total 24
drwxr-xr-x 3 root root  4096 Sep 14 22:22 .
drwxr-xr-x 7 root root  4096 Sep 14 22:22 ..
drwx------ 2 root root 16384 Sep 14 22:22 lost+found
root@vm:/root# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   24K   52M   1% /mnt/backups
```

**`oops.txt` is gone.** Not deleted — *covered*. The directory now shows the contents of the
mounted filesystem, and the same path answers to a different disk. `df` proves it: 56 MB where a
moment ago there were 252 GB.

Work in it normally:

```
root@vm:/root# mkdir /mnt/backups/nightly
root@vm:/root# touch /mnt/backups/nightly/2026-09-14.tar.gz
root@vm:/root# ls -R /mnt/backups
/mnt/backups:
lost+found  nightly

/mnt/backups/nightly:
2026-09-14.tar.gz
```

And unmount:

```
root@vm:/root# umount /mnt/backups
root@vm:/root# ls -la /mnt/backups
total 12
drwxr-xr-x 2 root root 4096 Sep 14 22:22 .
drwxr-xr-x 7 root root 4096 Sep 14 22:22 ..
-rw-r--r-- 1 root root   25 Sep 14 22:22 oops.txt
root@vm:/root# cat /mnt/backups/oops.txt
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
root@vm:/root# cat /etc/fstab
# UNCONFIGURED FSTAB FOR BASE SYSTEM
```

Empty, on this machine, because it is a virtual machine whose root filesystem was mounted by the
thing that started it rather than from a table. On a normal installation it has a line per
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
them:

```
root@vm:/root# blkid /dev/loop0
/dev/loop0: LABEL="backups" UUID="c26bf719-319e-4ab2-9b16-e641c60ab92e" BLOCK_SIZE="4096" TYPE="ext4"
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
