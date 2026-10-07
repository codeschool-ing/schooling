---
title: What a backup is for
version: 1
---

A **backup** is a copy of data, kept separately from the original, that can be used to bring the data
back after it has been lost or damaged. Every word of that definition carries weight, and the common
mistakes each drop one.

**Separately** rules out a lot of things people call backups:

| what people have | why it is not a backup |
|---|---|
| a second disk in the same server, mirrored (RAID 1) | a deletion, a corruption or ransomware happens on both disks at once |
| a folder synchronised to the cloud | the sync faithfully copies the deletion, or the encrypted files, within seconds |
| a database replica on another server | the replica applies every change, including `DELETE FROM orders` |
| a copy on the same server, in another folder | whatever destroys the server destroys the copy |

All four are valuable, and all four protect **availability against hardware failure**: a disk dies, the
other keeps serving. None protects against the three things a backup exists for: **mistakes**
(somebody deleted the wrong folder), **corruption** (a bug or a failing disk silently damaged the
data) and **attacks** (ransomware encrypted everything it could reach). Against those, a copy that
mirrors every change is a second victim.

**Can be used to bring the data back** is the part most often assumed and least often checked. A
backup that cannot be restored, or restores the wrong thing, is not a backup; it is a reassuring file.
Two sections on, the shop's own job turns out to be exactly that.

### Versions, not just copies

A backup protects against damage that is noticed late only if it keeps **old versions**. If the
backup overwrites itself every night and a file was corrupted a week ago, every copy is now of the
corrupted file. So backups are kept with a **retention**: the last seven nights, the last four
Sundays, the last twelve month-ends, for example. Ransomware that quietly encrypts files for a while
before announcing itself is the reason retention matters.

### Resilience

**Resilience** is the wider property a backup belongs to: the ability to keep working through a
failure and to recover from it afterwards. It has two halves, and lesson 1's availability needs both:

- **staying up**: redundancy, a second disk, a second server, a second internet connection, so that
  one failure does not stop the shop;
- **coming back**: backups and a practised plan to restore them, for the failures redundancy cannot
  absorb.

Redundancy is fast and copies everything, including the damage. Backups are slow and keep the past.
A resilient shop has both, and knows which one to reach for.
