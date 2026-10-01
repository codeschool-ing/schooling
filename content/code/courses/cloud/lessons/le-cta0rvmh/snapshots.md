---
title: "Snapshots: one instant, kept somewhere else"
version: 1
---

A snapshot is **a copy of a volume as it was at one instant**, taken while the volume stays in
use. It is how a volume is backed up, how it is copied to another zone, and how new volumes are
started from a known state.

Three facts about how snapshots are stored decide what they cost and what they protect.

**The first snapshot copies every block that has been written; each later one copies only what
changed since.** A 200 GB volume holding 60 GB of data gives a first snapshot of about 60 GB. If
2 GB change the next day, the second snapshot adds about 2 GB. Each one still restores the whole
volume, because it points at the blocks the earlier ones already hold, and deleting an old snapshot
keeps whatever blocks a later one still needs.

**Snapshots are kept in the provider's object storage, not in the volume's zone.** That is what
lets them survive the loss of a zone, and what lets a volume be recreated in any zone of the same
region. They do not show up as objects in any bucket of yours; the provider uses its object store
underneath and gives you a snapshot id.

**Restoring does not rewind the volume; it makes a new one.** You create a volume from the snapshot,
in the zone you choose, and attach it to an instance. The old volume is untouched, which is often
what you want when the question is what a file looked like on Tuesday.

Snapshot storage is billed per GB-month on what the snapshots hold, not on the size of the volume.
The `snapshot` line in the previous section's capture is 0.0680 in `sa-east-1`. A month of daily
snapshots of that 200 GB volume, with its 60 GB of data and 2 GB changing a day, holds the first
full copy plus 29 increments:

- 60 + 29 × 2 = 118 GB of snapshot data
- 118 × 0.0680 = 8.02 USD for the month, beside the volume's own 30.40

## A snapshot is not a backup policy

A schedule of snapshots is a good start with two gaps in it.

**The snapshots live in the same account and the same region as the volume.** Whoever can delete the
volume can usually delete its snapshots too, whether that is a colleague's cleanup script, an
attacker holding stolen credentials, or you on a bad afternoon. A region that goes down takes both
out of reach together.

And a snapshot of a running database is only as consistent as the disk was at that instant. It is
**crash-consistent**, the state a server is in after somebody pulls the plug. A database with a
write-ahead log recovers from that, usually, which is not the same as a backup the database made
itself and somebody has restored to prove it works.

A backup policy says how long copies are kept, where one copy lives that the production account
cannot delete, and when somebody last restored one. Copying snapshots to another account or region
is a feature every provider offers, and a decision nobody makes for you. Who may delete what is
lesson 7's subject, and `cloud-security` takes it further.
