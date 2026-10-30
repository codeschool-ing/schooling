---
title: Hyperdisk, where performance is bought separately
version: 1
---

A persistent disk ties its speed to its size, so the way to make one faster is to make it larger
and pay for space you may never fill. **Hyperdisk separates the three things a disk sells: capacity,
operations per second and throughput are each provisioned and priced on their own.** The newest
machine series, N4 and C4 among them, attach only Hyperdisk, which is why lesson 1 called it out.

## What Hyperdisk Balanced charges for

Google's disk page prices Hyperdisk Balanced in three parts, and states a baseline that comes with
every disk at no extra charge: **3,000 IOPS and 140 MBps**. Only what you provision above that is
billed. In Iowa on 30 October 2026, the page listed:

| part | price per hour | per month of 730 hours |
|---|---|---|
| capacity | 0.000109589 per GiB | 0.08 per GiB |
| IOPS above 3,000 | 0.000006849 per IOPS | about 0.005 per IOPS |
| throughput above 140 MBps | 0.000054795 per MBps | about 0.04 per MBps |

So a 100 GiB disk at the baseline is 8 dollars a month, less than a `pd-balanced` of the same size.
Raise it to 6,000 IOPS and 290 MBps for a database, and the extra 3,000 IOPS add about 15 dollars
and the extra 150 MBps about 6, **29 dollars in all**, for a performance that a persistent disk would
only reach by being several times larger.

## Writing one

For the `orders` database on an N4 machine, in a folder `hyperdisk`:

```hcl
# hyperdisk/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_compute_disk" "orders_db" {
  name                   = "orders-db"
  type                   = "hyperdisk-balanced"
  zone                   = "southamerica-east1-a"
  size                   = 100
  provisioned_iops       = 6000
  provisioned_throughput = 290
}

resource "google_compute_instance" "orders_db" {
  name         = "orders-db-1"
  machine_type = "n4-standard-4"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      type  = "hyperdisk-balanced"
    }
  }

  attached_disk {
    source = google_compute_disk.orders_db.id
  }

  network_interface {
    network = "default"
  }
}
```

```
ana@laptop:~/gcp/hyperdisk$ terraform plan -no-color | grep -E '^  #|provisioned_|^              \+ type|^Plan'
  # google_compute_disk.orders_db will be created
      + provisioned_iops               = 6000
      + provisioned_throughput         = 290
  # google_compute_instance.orders_db will be created
              + provisioned_iops       = (known after apply)
              + provisioned_throughput = (known after apply)
              + type                   = "hyperdisk-balanced"
Plan: 2 to add, 0 to change, 0 to destroy.
```

**The boot disk has to be Hyperdisk too.** An N4 cannot boot from a persistent disk, and the plan
cannot know that: change `hyperdisk-balanced` to `pd-balanced` on either disk and it plans just as
cleanly. The refusal would come from Compute Engine at creation, the same limit lessons 1 and 2 met.

## Changing it later

Hyperdisk's numbers can be changed on a disk in use, upwards and downwards within limits, and
Google spaces such changes out: the documentation allows one change to the provisioned performance
every few hours per disk. That turns a performance problem from a migration into an edit: raise the
IOPS before the end-of-month report, lower them afterwards, and pay for the higher number only while
it was set. With a persistent disk the same need means a larger disk, and a disk cannot shrink.
