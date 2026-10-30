---
title: The control plane Google runs, and what it costs
version: 1
---

A Kubernetes cluster is two halves: the **control plane**, which stores the cluster's state and
decides what runs where, and the **nodes**, which run the pods. GKE Standard splits the work along
that line. **Google runs the control plane, patches it and keeps it available; you choose, pay for
and look after the nodes.** This lesson is about the second half, because it is the half that
stays yours, but it starts with what the first half is and what it costs.

## What Google runs

The control plane is the API server, etcd, the scheduler and the controller manager, the
components the `kubernetes` course installs by hand. On GKE none of them appears in your project.
There is no virtual machine to see, no disk to back up and no version of etcd to choose. You reach
the control plane through its endpoint, with `kubectl`, and everything behind that endpoint is
Google's.

The one decision you make about it is **where it lives**:

- a **zonal** cluster has one control plane in one zone. If that zone has a problem, the API
  server is unreachable: pods already running keep running, but nothing can be scheduled,
  scaled or changed until it is back;
- a **regional** cluster has its control plane replicated across the region's zones, and its
  nodes spread across them too. It survives the loss of a zone, and Google's service level for it
  is higher.

The choice is made when the cluster is created and cannot be changed afterwards, which makes it
the first line of the cluster's definition rather than a detail.

## Writing the cluster down

Create a folder `gke` in `~/gcp` and save this as `main.tf` in it. It is the shop's cluster:
regional, on the regular release channel, with a maintenance window and Workload Identity, which
sections 04 and 05 and lesson 15 explain in turn:

```hcl
# gke/main.tf
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

resource "google_container_cluster" "shop" {
  name                = "shop"
  location            = "southamerica-east1"
  deletion_protection = false

  release_channel {
    channel = "REGULAR"
  }

  maintenance_policy {
    recurring_window {
      start_time = "2026-11-07T05:00:00Z"
      end_time   = "2026-11-07T11:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
    maintenance_exclusion {
      exclusion_name = "black-friday"
      start_time     = "2026-11-25T00:00:00Z"
      end_time       = "2026-12-02T00:00:00Z"
      exclusion_options {
        scope = "NO_UPGRADES"
      }
    }
  }

  workload_identity_config {
    workload_pool = "planner-dev.svc.id.goog"
  }
}
```

**`location` is a region, so this is a regional cluster.** A zone there, such as
`southamerica-east1-a`, would make it zonal. Notice what is missing: no node pool. The cluster
resource only describes the control plane, and the nodes come in section 03 as a resource of their
own. After `terraform init`, the plan for the cluster alone:

```
ana@laptop:~/gcp/gke$ terraform plan -no-color | grep -E '^  #|\+ location|channel|workload_pool|^Plan'
  # google_container_cluster.shop will be created
      + location                                 = "southamerica-east1"
      + release_channel {
          + channel = "REGULAR"
          + workload_pool = "planner-dev.svc.id.goog"
Plan: 1 to add, 0 to change, 0 to destroy.
```

## What the control plane costs

GKE charges a flat fee per cluster for the control plane, whatever its size, and gives every
billing account a monthly credit against it:

```
ana@laptop:~/gcp$ python3 prices.py serverless | grep -E 'cluster|credit'
  cluster management fee                                 0.1  per cluster-hour
  free credit each month, per billing account           74.4  dollars
```

**0.10 an hour is 73 dollars for a 730-hour month, and the credit of 74.40 covers one cluster.**
Google's pricing page describes the credit as the equivalent of one free Autopilot or zonal
Standard cluster a month. The shop's cluster is regional, so plan on paying its fee, and a second
cluster always pays.
Clusters are cheap to create and each one adds 73 dollars a month before a single node exists;
"one cluster per developer" is the habit that makes that number visible.

The nodes are separate, billed as the Compute Engine machines they are. That is the half the rest
of this lesson is about.
