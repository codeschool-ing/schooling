---
title: "Disks, stop and terminate: what survives"
version: 1
---

On a computer under a desk, the disk is inside the box and switching the box off does nothing to
it. **An instance has two kinds of disk, and they behave in opposite ways** when it is switched off,
which is why "I stopped it and my files were gone" and "I deleted it and I am still being billed"
are both things people say in their first month.

## A network volume and a local disk

The root disk of an ordinary instance is not in the host at all. It is a **network volume**, a block
device served by a storage system elsewhere in the same zone and attached to the instance over the
network. On AWS this is EBS, and lesson 5 puts it beside the other kinds of storage. Because the
volume lives apart from the host, it outlives the host: stop the instance, and the volume waits,
with every file on it, until the instance starts again somewhere else.

It is billed while it waits. A `gp3` volume is 0.1520 USD per GB-month in `sa-east-1` on the sheet,
so the 20 GB root disk of a stopped instance costs 3.04 USD a month for as long as nobody deletes
it.

The other kind is the **instance store**: disks physically inside the host, the `d` in a type such
as `m7gd.large`. They are fast, because nothing stands between the instance and the disk, and they
are included in the instance's price. They also belong to the host. When the instance stops, it
leaves the host and the disks stay behind, and whatever was on them is gone. A reboot keeps them,
because a reboot does not leave the host.

## Reboot, stop, terminate

| | reboot | stop | terminate |
|---|---|---|---|
| the instance | restarts on the same host | switched off, host released | deleted, for good |
| the root network volume | kept | kept, and still billed | deleted with it, unless you said otherwise |
| the instance store | kept | erased | erased |
| a public IPv4 address given at launch | kept | released; a new one at start | released |
| processor charge | continues | stops | stops |

Two rows catch people. **Stop is not a pause button for the disk bill**: the root volume keeps
charging. And **the public address changes** on a stop and start, because the provider lends
public IPv4 addresses from a pool; anything that pointed at the old address, a DNS record or a
colleague's bookmark, now points at somebody else. Keeping one fixed is a separate, billed
resource: a public IPv4 address is 0.0050 USD an hour on the sheet, 3.65 USD a month at 730 hours.

## What a replacement loses

So far every row assumed the same instance comes back. In the second half of this lesson it does
not: a group replaces a failing instance with a new one launched from the image. **A replacement
keeps what is in the image and nothing else.** Everything written since that machine first booted
is gone with it: the files users uploaded to its disk, its log files, the configuration somebody
fixed by hand over SSH last Tuesday, a SQLite database in the home directory.

That is the difference behind an old phrase in operations, **pets and cattle**. A pet server has a
name, was set up by hand, and when it is ill somebody logs in and nurses it back to health, because
nothing else knows what is on it. Cattle are numbered, built from an image, and when one is ill it
is replaced, because every one of them is the same and the replacement is too.

Neither is a moral category. A single database server you look after carefully is a reasonable pet,
provided its disk has a backup. What goes wrong is a pet that everybody believes is cattle: a
machine in a group, replaced one night by the group doing its job, taking the only copy of
something with it. The last section of this lesson is about keeping that something elsewhere.
