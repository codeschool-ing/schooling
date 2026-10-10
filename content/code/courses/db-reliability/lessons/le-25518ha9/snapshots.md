---
title: Snapshots, and the filesystem frozen in place
version: 1
---

Copying a terabyte file by file takes hours. A **snapshot** takes a second, whatever the size: a
storage layer that can snapshot (LVM, ZFS, btrfs, a cloud provider's disks, a SAN, your hypervisor)
records the state of a whole volume at an instant and keeps the old blocks as the live volume
changes. It is the fastest backup there is, and the one most often taken wrongly.

## What a snapshot of a running server is

A snapshot of the volume holding a running server's data directory captures the files as they were
at one instant, **as if the power had been cut at that instant**. That state is called
**crash-consistent**, and PostgreSQL is built to survive it: the write-ahead log is written before
the data, so a server started on a crash-consistent copy replays the log and arrives at a
consistent database. A snapshot is therefore safe in a way `cp` was not, because every file is from
the same moment.

The condition is **every file from the same moment**, and it fails the day the data and the log
live on two volumes, which is a common recommendation for performance:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two volumes, data and write-ahead log. Above, each is snapshotted separately, the data at 10:00:00.000 and the log at 10:00:00.400, so the log describes 400 ms of changes the data copy lacks. Below, both are snapshotted as one atomic group, at the same instant.\"><defs><marker id=\"l3v-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"l3v-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data volume</text><rect x=\"20\" y=\"66\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">WAL volume</text><rect x=\"20\" y=\"140\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data volume</text><rect x=\"20\" y=\"186\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">WAL volume</text><path d=\"M180 38 L230 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3v-pa)\"></path><text x=\"240\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">snapshot at 10:00:00.000</text><path d=\"M180 84 L230 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3v-pa)\"></path><text x=\"240\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">snapshot at 10:00:00.400</text><rect x=\"470\" y=\"34\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">400 ms of log describe</text><text x=\"585\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">changes the data copy lacks</text><path d=\"M180 158 L210 158 L210 204 L180 204\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M210 181 L240 181\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3v-ph)\"></path><rect x=\"250\" y=\"158\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">one atomic group</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">both at the same instant</text></svg>", "caption": "Data and log on two volumes. Snapshotted one after the other they are two crashes, not one; only an atomic group snapshot makes them the same instant."}
```

Two snapshots, even taken a few hundred milliseconds apart, are no longer one crash. The log can be
behind the data it is supposed to explain, and the server started on the pair replays the wrong
history or refuses to start. A snapshot of several volumes is only safe if the storage takes them
**atomically, as a group**, which most cloud providers offer under a name like a consistency group
or a multi-volume snapshot, and which has to be asked for.

## The two safe ways

1. **One atomic snapshot of everything the server writes**: data directory, write-ahead log and any
   tablespace, in a single snapshot or a group the storage guarantees is atomic. Restore it and
   start the server: it runs crash recovery, exactly as after a power cut.
2. **Tell PostgreSQL a backup is starting.** In SQL, `SELECT pg_backup_start('label')` before the
   snapshot and `SELECT * FROM pg_backup_stop()` after it, in the same session, makes the server
   hand back the text of the same `backup_label` the base backup had. You write it into the copy,
   and a copy taken at different moments can then be repaired with the log. This is the
   conversation `pg_basebackup` has for you.

The filesystem's own freeze, `fsfreeze` on Linux, holds every write to a volume while a snapshot is
taken, which makes one volume's snapshot clean at the filesystem level. It does not make two volumes
one moment, and **with PostgreSQL it adds little**: the server's own log already makes a single
volume's crash-consistent copy safe.

## Your virtual machine is a snapshot machine

Lesson 1 suggested snapshotting the virtual machine at the end of the setup. Taken while the
machine is running, that snapshot is crash-consistent for everything inside it, PostgreSQL
included, because the whole machine's disk is one volume. It is a good way to undo an afternoon. It
is not a backup in this course's sense, for the reason lesson 9 spends its time on: **it lives on
the same computer as the thing it protects.**

This lab has no volume manager to take snapshots with, so this section is read rather than typed.
