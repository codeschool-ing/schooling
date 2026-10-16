---
title: Snapshots, and why the second one is cheap
version: 1
---

A snapshot sounds like a copy of a disk, and a copy of a 100 GB disk sounds like another 100 GB to
pay for every time you take one. **A snapshot stores the blocks that changed since the snapshot
before it**, and nothing else. The first snapshot of a volume holds every block that was ever
written; each one after it holds only what is new, and points back at the older blocks it still
needs.

## Taking two

A volume of 100 GB, and two snapshots of it a day apart:

```
ana@laptop:~/aws$ VOL=$(aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --query VolumeId --output text)
ana@laptop:~/aws$ SNAP=$(aws ec2 create-snapshot --volume-id "$VOL" --description "orders, Monday" --query SnapshotId --output text)
ana@laptop:~/aws$ aws ec2 create-snapshot --volume-id "$VOL" --description "orders, Tuesday"
{
    "Tags": [],
    "StorageTier": "standard",
    "SnapshotId": "snap-a9866757c0726a8a2",
    "VolumeId": "vol-03bc20f80bd5f6780",
    "State": "completed",
    "StartTime": "2026-10-16T16:25:21+00:00",
    "Progress": "100%",
    "OwnerId": "123456789012",
    "Description": "orders, Tuesday",
    "VolumeSize": 100,
    "Encrypted": false
}
ana@laptop:~/aws$ aws ec2 describe-snapshots --filters Name=volume-id,Values="$VOL" --query "Snapshots[].[SnapshotId,VolumeSize,State,Description]" --output table
-------------------------------------------------------------------
|                        DescribeSnapshots                        |
+-------------------------+------+------------+-------------------+
|  snap-8c825a3b1a1702295 |  100 |  completed |  orders, Monday   |
|  snap-a9866757c0726a8a2 |  100 |  completed |  orders, Tuesday  |
+-------------------------+------+------------+-------------------+
```

The first command keeps the volume's id in `VOL` and the second keeps the Monday snapshot's id in
`SNAP`, so the commands after them can use both; your ids will differ from these. moto reports both
snapshots as `completed` and `100%` the instant it is asked, and both show `VolumeSize` 100.

Neither number is a measurement. `VolumeSize` is the size of the **volume** the snapshot was taken
from, not what the snapshot stores, and moto stores no blocks at all. On AWS a snapshot starts
`pending` and reaches `completed` minutes or hours later, depending on how much changed; the volume
stays usable the whole time, because the snapshot is of the moment it was asked for. What it stores
is never printed by `describe-snapshots`. **AWS bills it, and that is where you see it.**

@@FIG:incremental@@

The figure is the part moto cannot show. Monday's snapshot holds the six blocks that had been
written. Tuesday's holds the two that changed since, and refers to Monday's for the other four.
**Delete Monday's, and Tuesday's is still whole**: AWS keeps the blocks a later snapshot still
needs, and frees only the ones nothing points at. You can therefore delete any snapshot in a chain
without breaking the others, and the bill only falls by what was unique to it.

## What it costs

The price sheet of 16 October 2026 says 0.068 USD per GB-month for a snapshot in `sa-east-1`, on
what the snapshot stores. Take the volume above, with 60 GB of it written, and a nightly snapshot
kept for 30 days, with 3 GB changing each day:

| | stored | per month |
|---|---|---|
| the first snapshot | 60 GB | 4.08 USD |
| 29 more, 3 GB each | 87 GB | 5.92 USD |
| all 30 | 147 GB | 10.00 USD |

Thirty full copies would have been 1,800 GB and 122.40 USD. **Empty blocks are never stored**, so
the first snapshot costs what was written, not the size of the volume. And the figure that grows is
the change rate: a database that rewrites 30 GB a night is a different bill from a web server's
root disk that changes a few megabytes.

## Restoring one

A snapshot becomes useful again as a new volume, and **a snapshot belongs to the region, not to a
zone**:

```
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1c --snapshot-id "$SNAP" --volume-type gp3 --query "[VolumeId,AvailabilityZone,Size,SnapshotId]" --output text
vol-097c5b072b0ebbc79	sa-east-1c	100	snap-8c825a3b1a1702295
```

The volume was taken in `sa-east-1a` and the new one was made in `sa-east-1c`. That is the
ordinary way to move a volume between zones, which lesson 3 needs, since a volume itself never
leaves the zone it was made in.

The second command is moto being lenient again:

```
ana@laptop:~/aws$ aws ec2 create-volume --availability-zone sa-east-1a --snapshot-id "$SNAP" --size 50 --volume-type gp3 --query "[VolumeId,Size]" --output text
vol-646726d597c884e30	50
```

It made a 50 GB volume from a 100 GB snapshot. **AWS refuses this**: a volume made from a snapshot
must be at least the snapshot's volume size, and may be larger, after which the file system inside
has to be grown to use the extra space. A shrink is done inside the operating system, by copying the
files to a smaller volume.

One more behaviour of AWS that moto has no way to show. A restored volume is usable at once, but
**its blocks arrive from the snapshot the first time each one is read**, so the first pass over a
restored database disk is much slower than the second. Reading every block once after restoring
warms it; AWS also sells Fast Snapshot Restore, which removes the delay for named snapshots in
named zones, at an hourly price that is not on the sheet.

## What a snapshot does not guarantee

A snapshot is of the **blocks**, at an instant, and knows nothing about the files above them. For
a disk that is mostly read, such as a root volume, that is fine. For a database in the middle of
writing, it is the state the disk would be in after a power cut: the database will recover, as it
does after a crash, but whatever was in memory and unflushed is not in the snapshot. Taking a
consistent one means asking the application first: flushing and freezing the file system, using
the database's own backup, or stopping the instance. The image in the next section is made the
safe way by default, by rebooting the instance first.
