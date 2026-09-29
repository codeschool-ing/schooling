---
title: "Block volumes: a disk at the end of a cable"
version: 1
---

A block volume is what lesson 4's virtual machine boots from, and what it is given when it needs
more room. **It is a network device, not a disk inside the server**: the provider keeps the data on
its own storage fleet and presents it to the instance as though it were local. That is why a volume
outlives the instance it was attached to, and why it can be detached from one instance and
attached to another.

Three properties follow from how it is built.

**A volume lives in one availability zone.** It is replicated inside that zone, so one failing drive
does not lose it, but an instance in another zone cannot attach it. Moving a volume to another zone
means copying it, which is what the next section's snapshots are for. Azure and Google also sell
disks replicated across two or three zones, at a higher price; the default in all three is one
zone. Lesson 9 says what a zone is and why losing one is something that happens.

**A volume is attached to one instance at a time.** Two machines writing blocks to the same disk
would each keep their own idea of the filesystem in memory and corrupt it within minutes, so the
default forbids it. A few provisioned-IOPS volume types can be attached to several instances in the
same zone, and that works only with a filesystem designed for shared disks, which ext4 and XFS are
not. When several machines need the same files, the answer is the file service two sections on.

**A volume is paid for per GB provisioned, not per GB used.** You pick a size when you create it
and the meter runs on that size, whether the filesystem inside is full or empty. These are the
sheet's EBS lines, from the same pinned public price list the rest of the course reads, in USD per
GB-month:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -A3 '^EBS'
EBS, USD per GB-month
  gp3 SSD volume                           0.1520       0.0800
  st1 HDD volume                           0.0860       0.0450
  snapshot                                 0.0680       0.0500
```

A 200 GB `gp3` volume in `sa-east-1` costs 200 × 0.1520 = 30.40 USD a month from the moment it
exists, attached or not. A volume left behind after its instance was terminated keeps billing, and
it is one of the commonest lines on a bill nobody can explain; lesson 10 comes back to it.

## Size, IOPS and throughput are separate dials

A disk is fast or slow in two different ways. **IOPS** counts operations per second: how many
separate small reads or writes the volume will do. **Throughput** counts bytes per second: how
quickly a long sequential read streams. A database reading thousands of 8 KB pages at scattered
places needs IOPS; a job reading a 50 GB file from start to end needs throughput. On older volume
types both grew with the size, so people bought a bigger disk to get a faster one.

`gp3`, the general-purpose SSD in the sheet, separates them. It comes with a baseline of 3,000 IOPS
and 125 MiB/s whatever its size, and more of either is bought on its own, without adding gigabytes.
`st1` is a hard-disk volume built for the other kind of work: cheaper per GB, 0.0860 against 0.1520
in São Paulo, quick at long sequential reads and slow at scattered ones, and it cannot be a boot
volume. Choosing between them is a question about the access pattern, not about the size.

The volume gives you nothing above the blocks. **Formatting, mounting, growing the
filesystem after the volume grows, and checking it after a crash are the operating system's job**,
which in the terms of lesson 1 makes them yours.
