---
title: The filesystem, and the mount options to leave alone
version: 1
---

It is tempting to think a database wants something exotic underneath it: raw devices, a special
filesystem, a tuning guide's worth of mount options. PostgreSQL wants the opposite. **It keeps its
data in ordinary files and leans on the operating system for caching and for writing them out**,
which is why lesson 6 sized its own cache against the kernel's. So the filesystem should be the
most ordinary, best-tested one your distribution offers.

On Linux that means one of two:

| filesystem | where you meet it |
|---|---|
| **ext4** | the default on Ubuntu and Debian, and what the course's server uses |
| **XFS** | the default on Red Hat Enterprise Linux and its relatives |

Both are mature, both are what PostgreSQL is tested on most, and the difference in speed between
them for a database is small next to the difference between disks. **Pick the one your
distribution installs by default** and spend the attention on the disk. ZFS and btrfs work too,
and bring snapshots and checksums of their own along with a tuning story of their own; they are a
choice somebody makes on purpose, never one to drift into. A network filesystem such as NFS is the
one to avoid for a data directory unless the storage vendor documents it for databases, because
a write the server considers done may still be on its way somewhere else.

## Reading the options of the filesystem you have

`findmnt --target` names the filesystem a path lives on, its type and the options it was mounted with:

```
ana@db:~$ findmnt --target /var/lib/postgresql/16/main --output TARGET,FSTYPE,OPTIONS
TARGET FSTYPE OPTIONS
/      ext4   rw,relatime,discard,no_prefetch_block_bitmaps,resv_strict,resuid=65534,resgid=65534
```

This is the recording machine, so most of those options belong to the computer it
ran on, and yours will be shorter: typically something like `rw,relatime`. The data directory is on the root filesystem, which is normal for a small server and
fine for this course. A server that matters gets **a filesystem of its own for the data**, so the
operating system's logs and a user's downloads cannot fill the disk under the database, and so
the database cannot fill the disk under the operating system.

## Which options matter

**`relatime`**, the default, updates a file's access time at most once a day. `noatime` stops it
altogether, which saves a small write after reads and costs nothing PostgreSQL uses. It is the one
option worth adding.

**Write barriers are the ones never to remove.** A barrier is the filesystem telling the disk to
put what it has accepted onto stable storage before it accepts more, and it is what makes an
`fsync` mean anything. ext4 still accepts `barrier=0` and old guides still recommend it for speed.
With it, a power cut can lose transactions that PostgreSQL already reported as committed, and can
corrupt the files in ways no recovery repairs. XFS removed its version of the option for exactly
that reason.

A filesystem made for the data, mounted at boot, is one line in `/etc/fstab`. Find the
filesystem's identifier with `sudo blkid`, and use it rather than a device name, which can change
between boots:

```conf
UUID=<the uuid blkid printed>  /var/lib/postgresql  ext4  defaults,noatime  0  2
```

Mount it before installing PostgreSQL, or stop the cluster and move the directory onto it first.
**A data directory whose filesystem failed to mount is an empty directory**, and a server started
on it is a server with no data.
