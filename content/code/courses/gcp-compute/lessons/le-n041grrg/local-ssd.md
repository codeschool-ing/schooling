---
title: Local SSD, fast and temporary
version: 1
---

Every disk so far reached the machine over the network. **A local SSD is physically attached to the
host the machine runs on, which makes it much faster and makes its contents belong to that host
rather than to you.** When the machine leaves the host, the data stays behind and is erased.

## What it is for

The speed comes from skipping the network, and the price of that is durability. Treat a local SSD
as scratch space: a cache that can be rebuilt, the temporary files of a sort that spills to disk,
the intermediate results of a batch job that can start again. **Never the only copy of anything.**

It comes in fixed slices of **375 GiB**, attached when the machine is created and never afterwards.
On older series such as N2 you add them yourself; on newer ones the slices come with the machine
type, which is what the `-lssd` suffix in lesson 1 meant. On an N2, in a folder `scratch`:

```hcl
# scratch/main.tf
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

resource "google_compute_instance" "photos_worker" {
  name         = "photos-worker-1"
  machine_type = "n2-standard-4"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  scratch_disk {
    interface = "NVME"
  }

  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = "default"
  }
}
```

```
ana@laptop:~/gcp/scratch$ terraform plan -no-color | grep -E '^  #|scratch_disk|^          \+ (interface|size) |^Plan'
  # google_compute_instance.photos_worker will be created
      + scratch_disk {
          + interface   = "NVME"
          + size        = 375
      + scratch_disk {
          + interface   = "NVME"
          + size        = 375
Plan: 1 to add, 0 to change, 0 to destroy.
```

Two blocks, two slices, 750 GiB. Google's disk page prices local SSD at 0.08 per GiB-month, so one
slice is **30 dollars a month** and these two are 60, charged for as long as the machine exists,
whether or not anything is written to them.

## When the data survives, and when it does not

The rule is about the host, and the documentation lists the cases:

| event | the local SSD's data |
|---|---|
| the guest operating system reboots | kept |
| live migration during host maintenance | kept: the data is copied to the new host |
| the machine is stopped or suspended | lost, unless you ask for it to be preserved, where the series allows it |
| the machine is deleted | lost |
| the host fails, or a Spot machine is preempted | lost |

The third row is the one that surprises people: **stopping a machine to save money empties its
local SSD.** So a job that keeps state on one has to write that state somewhere durable before a
stop, and lesson 6 adds preemption, the stop nobody asks for, to the same list.
