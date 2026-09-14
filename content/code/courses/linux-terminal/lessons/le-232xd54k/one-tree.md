---
title: One tree, no drive letters
version: 1
---

On Windows a path starts with a letter: `C:\Users\ana\notes.txt`. The letter says which physical
disk the file is on, and there is one namespace per disk.

Linux has no drive letters. **There is exactly one tree, it starts at `/`, and every disk in the
machine appears somewhere inside it.**

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
```

Read the two ends of that line together: `/dev/vda` is a disk — an entry in `/dev`, exactly as
section 09 described — and `/` is **where in the tree it was attached**. The disk is not the tree.
It is hung on a branch of it.

## Mounting is attaching a disk to a directory

The verb is *mount*, and it is the whole idea. You take a filesystem — a disk, a partition, a USB
stick, a share on another machine — and you say **which existing directory it should appear as**.
From that moment, opening that directory opens the disk.

So a second disk on a Linux machine does not become `D:`. It becomes a directory, and whoever set
the machine up chose which one:

| the disk | might appear at |
|---|---|
| a second internal drive | `/data`, `/srv`, `/home` |
| a USB stick you plugged in | `/media/ana/KINGSTON` |
| a share on another machine | `/mnt/backups` |
| the Windows disk, inside WSL | `/mnt/c` |

Lesson 3 does this properly — `mount`, `lsblk`, what happens when a disk is not there. What
matters now is the shape.

## What the shape changes for you

**A path never says which disk.** `/srv/data/report.csv` is a complete, unambiguous address, and
nothing in it tells you whether that lives on the main drive, a second one, or another machine
entirely. That is deliberate: **a program should not have to care, and does not.** Moving the data
to a bigger disk is a job for whoever runs the machine, and no path, script or program changes.

On Windows the drive letter is part of the address, so the same move breaks every path that named
`D:`.

**There is one place to look.** `cd /` and everything on the machine is under you. There is no
"which drive was that on", because there is no other tree to search.

**And the letters were never stable anyway.** A Windows drive letter is assigned in the order
things are found, so the same USB stick is `E:` on one machine and `G:` on another. A mount point
is a name somebody chose, written in a configuration file, and it is the same on every boot.

## Where this bites a beginner

**`/` is not `/home`.** The root of the tree is not your home directory. `~` (your home) is a
directory *inside* the tree, usually at `/home/yourname`, and the two get confused constantly.
Section 13 draws the map.

**An empty directory can be a mounted disk.** If nothing is mounted at `/mnt/backups`, it is just
an ordinary empty directory and writing there writes to the main disk. Lesson 11 has the version
of this that costs money: a backup job writing happily to a mount point where the disk fell off.

**And in WSL there are two trees, not one.** Your Linux home is `/home/you` and Windows is at
`/mnt/c` — mounted, like everything else. It works, it is slower, and files you keep there carry
Windows line endings. Section 12 is about exactly that.
