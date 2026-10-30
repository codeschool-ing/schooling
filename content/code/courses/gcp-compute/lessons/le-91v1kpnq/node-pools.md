---
title: Node pools
version: 1
---

**A node pool is a group of identical nodes**: one machine type, one disk, one image, one set of
labels. Underneath, each pool is a managed instance group of Compute Engine machines, the same kind
of group lesson 4 builds by hand, and GKE drives it for you. A cluster has as many pools as it has
kinds of node, and the pool is the unit you resize, upgrade and replace.

## Writing one down

Save this beside `main.tf`, in the same folder, as `pool.tf`. Terraform reads every `.tf` file in a
folder as one configuration, so the pool can refer to the cluster:

```hcl
# gke/pool.tf
resource "google_container_node_pool" "general" {
  name       = "general"
  cluster    = google_container_cluster.shop.id
  location   = "southamerica-east1"
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 50

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}
```

The plan now has two resources:

```
ana@laptop:~/gcp/gke$ terraform plan -no-color | grep -E '^  #|node_count|node_locations|machine_type|^Plan'
  # google_container_cluster.shop will be created
      + node_locations                           = (known after apply)
  # google_container_node_pool.general will be created
      + initial_node_count          = (known after apply)
      + node_count                  = 1
      + node_locations              = (known after apply)
          + max_node_count  = 3
          + min_node_count  = 1
          + machine_type       = "e2-standard-4"
Plan: 2 to add, 0 to change, 0 to destroy.
```

## The number that is per zone

`node_count = 1` reads like one node, and **in a regional cluster it is one node in each zone the
pool covers.** The shop's region has three zones, so the pool starts with three machines, and the
autoscaling bounds are per zone too: between three and nine nodes in all. `node_locations` is
`(known after apply)` in the plan because GKE chooses the zones when it builds the pool, unless you
list them.

That multiplication is the most common surprise on a first GKE bill:

```
ana@laptop:~/gcp$ python3 prices.py vm | grep -E 'per hour|e2-standard-4'
                                    per hour   per month   Spot/hour
  e2-standard-4   4 vCPU  16 GiB    0.13402284       97.84           -
ana@laptop:~/gcp$ python3 -c "print(round(3 * 0.13402284 * 730, 2))"
293.51
```

**Three `e2-standard-4` nodes are 293.51 dollars a month at the floor**, before the cluster fee.
That is what a regional cluster's availability costs: one node in each zone, so that losing a zone
loses a third of the capacity rather than all of it. A zonal cluster with one node would be 97.84,
and would be down for as long as its zone was.

## What else a pool decides

- **`management`** turns on two things GKE does to the pool's nodes: **auto-repair** replaces a
  node that fails its health checks, and **auto-upgrade** moves the nodes to new versions as the
  release channel offers them. Both default to on in release channels, and the second is
  section 04's subject.
- **`workload_metadata_config` with `GKE_METADATA`** is what lesson 15 depends on: pods on these
  nodes ask a GKE metadata server for credentials instead of reaching the node's own service
  account.
- **More than one pool** is how a cluster offers more than one kind of machine. The shop's photo
  resizing, which is batch work that can be interrupted, belongs on a second pool of Spot nodes
  with a taint, so that only pods tolerating interruption land there; lesson 6 explains why Spot
  fits that work, and lesson 14 shows Autopilot making the same choice per pod.

Changing a pool's machine type is not an edit in place. GKE creates new nodes and drains the old
ones, which is the same machinery as an upgrade, and the reason a pool's upgrade settings matter
even to a team that never upgrades by hand.
