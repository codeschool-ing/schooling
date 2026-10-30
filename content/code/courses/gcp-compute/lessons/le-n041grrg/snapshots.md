---
title: Snapshots, and the schedule that takes them
version: 1
---

A snapshot is a copy of a disk at one moment, kept apart from the disk. **The first snapshot of a
disk copies what is used; every later one copies only the blocks that changed since the one
before.** That is what makes a snapshot every night affordable, and it is the reason deleting an old
snapshot never breaks a newer one: Compute Engine moves whatever the newer one still needs.

## What they cost

Snapshots are billed for what they hold, compressed, and the sheet prices the two kinds:

```
ana@laptop:~/gcp$ python3 prices.py disks | grep snapshot
  standard snapshot                                     0.05  per GiB-month
  archive snapshot                                     0.019  per GiB-month
```

Take the `orders-data` disk from section 02: 100 GiB with 40 GiB in use, and about 1 GiB changing a
day. Fourteen nightly snapshots hold at most 40 GiB plus 13 days of changes, 53 GiB, and that is
**under 2.70 dollars a month** at 0.05 before compression makes it smaller still. The disk itself is
10. A team that skips snapshots to save money is saving very little.

**Archive** snapshots cost less to keep and are meant for copies kept for months: they are billed
for at least 90 days and charge to be read back, which suits a yearly copy kept for an audit and
does not suit the snapshot you restore on a bad Tuesday.

## A schedule, not a habit

A snapshot nobody remembers to take does not exist. A **snapshot schedule** is a resource policy
attached to the disk, and Compute Engine takes and deletes snapshots by it. In the same folder as
section 02, add this file next to `main.tf`:

```hcl
# disks/schedule.tf
resource "google_compute_resource_policy" "nightly" {
  name   = "nightly"
  region = "southamerica-east1"

  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }

    retention_policy {
      max_retention_days    = 14
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }

    snapshot_properties {
      storage_locations = ["southamerica-east1"]
    }
  }
}

resource "google_compute_disk_resource_policy_attachment" "orders_nightly" {
  name = google_compute_resource_policy.nightly.name
  disk = google_compute_disk.orders_data.name
  zone = "southamerica-east1-a"
}
```

```
ana@laptop:~/gcp/disks$ terraform plan -no-color | grep -E '^  #|start_time|max_retention_days|on_source_disk_delete|^Plan'
  # google_compute_disk.orders_data will be created
  # google_compute_disk_resource_policy_attachment.orders_nightly will be created
  # google_compute_instance.orders will be created
  # google_compute_region_disk.orders_ha will be created
  # google_compute_resource_policy.nightly will be created
              + max_retention_days    = 14
              + on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
                  + start_time    = "04:00"
Plan: 5 to add, 0 to change, 0 to destroy.
```

Three choices in that file deserve a sentence each. **`start_time` is in UTC**, so 04:00 is one in
the morning in São Paulo. **`max_retention_days`** is what keeps the bill at the number above
rather than growing every night. And **`KEEP_AUTO_SNAPSHOTS`** means that deleting the disk keeps
its snapshots, which is the point of having them: the day somebody deletes the wrong disk is the day
the snapshots are needed.

The provider does check one thing here that it did not check for machine types: the value of
`on_source_disk_delete` must be one of two words. Misspell it and the plan stops:

```
ana@laptop:~/gcp/disks$ sed -i 's/KEEP_AUTO_SNAPSHOTS/KEEP_SNAPSHOTS/' schedule.tf
ana@laptop:~/gcp/disks$ terraform plan -no-color

Error: expected snapshot_schedule_policy.0.retention_policy.0.on_source_disk_delete to be one of ["KEEP_AUTO_SNAPSHOTS" "APPLY_RETENTION_POLICY" ""], got KEEP_SNAPSHOTS

  with google_compute_resource_policy.nightly,
  on schedule.tf line 16, in resource "google_compute_resource_policy" "nightly":
  16:       on_source_disk_delete = "KEEP_SNAPSHOTS"
```

## Consistency

A snapshot of a disk in use is taken while the machine keeps writing, so it is **crash-consistent**:
what you would find after pulling the power. A file system recovers from that; a database usually
does, and sometimes needs its own recovery on restore. For data that matters, the safer habit is to
let the application flush before the snapshot, which is what the database's own backup tool is for,
and to treat the disk snapshot as the second line rather than the only one.

Restoring is making a new disk from the snapshot, never writing over the old one, so a restore can be
tested before anything is replaced.
