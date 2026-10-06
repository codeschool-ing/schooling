---
title: Proving the copy is intact
version: 1
---

A restore test proves the backup was right on the day it was tested. Between tests, the archive sits
on a disk, travels to an off-site location, is copied to a cloud service. Any of those can damage it:
a failing disk, an interrupted transfer, a bug in a copy tool. **The checksum from lesson 1 is how you
know the copy is still the backup.**

Right after the job, ana records a SHA-256 hash of the archive, then checks it:

```
root@db:~# sha256sum /backup/shop-2026-10-05.tar.gz > /backup/SHA256SUMS
root@db:~# sha256sum -c /backup/SHA256SUMS
/backup/shop-2026-10-05.tar.gz: OK
```

`SHA256SUMS` is a small text file holding the hash and the archive's name. `sha256sum -c` reads it,
hashes the archive again, and says `OK`: the file is byte for byte what it was when the hash was
taken.

Now the archive is copied for the off-site disk, and the copy is damaged. Here the damage is made on
purpose, so it can be seen: `dd` overwrites one byte of the copy with the letter `X`, which is what a
single bad sector or a corrupted transfer looks like.

```
root@db:~# cp /backup/shop-2026-10-05.tar.gz offsite.tar.gz
root@db:~# printf X | dd of=offsite.tar.gz bs=1 seek=200 conv=notrunc 2>/dev/null
root@db:~# cat /backup/SHA256SUMS; sha256sum offsite.tar.gz
e8d0846627c4ce345d291a73a47904fa3d305ae71b92d0988296bfad8c07cf4f  /backup/shop-2026-10-05.tar.gz
6342cb6d97c02abcc78151161db32157cee134930ad2a344d41d0f86840a3280  offsite.tar.gz
```

The recorded hash starts `e8d08466`; the copy's starts `6342cb6d`. One byte out of the whole archive
changed, and the hash says so beyond doubt. Without the check, the damage would surface only on the
day somebody needed that copy, which is the worst possible day to find out.

### A routine, not a heroic act

Put together, the shop's backup routine fits on an index card:

1. the job includes everything under `/srv/shop` and runs every night;
2. right after it, a hash of the archive is recorded beside it;
3. every copy, off site or in the cloud, is checked against that hash after it arrives;
4. once a month, ana restores the latest archive into an empty folder and compares it with the live
   data, and writes down how long it took;
5. once a year, the owners and ana walk through restoring the whole shop on a different machine, as
   lesson 10's tabletop exercise, with the timing compared against the RTO.

The fourth step is the one that found the missing invoices, and it is the one that gets skipped when
everybody is busy. It is also the cheapest insurance the shop has: half an hour a month against losing
the documents the business is legally obliged to keep.
