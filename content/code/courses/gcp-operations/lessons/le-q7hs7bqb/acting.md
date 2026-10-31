---
title: Acting on a recommendation without breaking anything
version: 1
---

**Shrinking or deleting is reversible only if you planned for it to be.** A machine resized to half its type and
too small comes back with one command; a machine deleted with its disk does not come back at all. The shop's
procedure is built so that every step before the last can be undone. Nothing here ran: the machines are Compute
Engine's.

## Shrinking

A machine's type can be changed only while it is stopped:

```sh
gcloud compute instances stop reports --zone=southamerica-east1-a
gcloud compute instances set-machine-type reports --zone=southamerica-east1-a --machine-type=e2-standard-4
gcloud compute instances start reports --zone=southamerica-east1-a
```

Not run. That is a few minutes of downtime, so it is done in the machine's quiet hours and announced to its owner.
Then watch it for the next full cycle (a week, or a month for the reports): if its 95th percentile now sits above
80%, the shrink was one step too far, and the same three commands go back.

**The commitment of lesson 21 has to be considered first.** A resource-based commitment to 32 GB of memory does not
shrink when `reports` does; the saving from the smaller machine is real only for usage that was paid on demand.

## Deleting the idle machine

`old-migration` goes through four steps, a week apart, because each one gives its owner a chance to say "that was
mine":

1. **Find the owner** from its labels (`team`, from lesson 5's `default_labels`) or from the audit log entry that
   created it. A machine with neither is lesson 23's problem, and the reason that lesson exists.
2. **Label it** `delete-after=2026-11-20` and tell the owner, or the team channel if there is none.
3. **Snapshot its disk, then stop it.** A stopped machine costs nothing for its CPU and memory; its disk is still
   billed, and the snapshot costs less than the disk. If something breaks, starting the machine brings it all back.
4. **Delete it** on the date, with the snapshot kept for a further month.

The same shape applies to the other idle resources: an **unattached disk** is snapshotted and deleted; a **reserved
IP address** in use by nothing is released. An address that is reserved but unused is billed by the hour, and
releasing it is free, though the same address cannot be guaranteed again.

## Making it a habit

The shop reviews the Recommender's open recommendations on the first Monday of each month, with the machines' owners,
in fifteen minutes. **A recommendation dismissed is dismissed with a reason**, written in its state, so that next
month's review does not argue the same machine again. And the four-step deletion of idle machines is the one place
where the shop is willing to be slow on purpose: the cost of a week's delay is a few dollars, and the cost of deleting
somebody's only copy of something is not measured in dollars.
