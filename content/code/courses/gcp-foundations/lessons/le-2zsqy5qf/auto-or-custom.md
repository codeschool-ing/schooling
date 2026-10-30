---
title: Auto mode or custom mode
version: 1
---

**Auto mode is convenient once and expensive later.** An auto mode network takes one subnet in every region,
each a `/20` cut from the same block, `10.128.0.0/9`, and gcloud's own help calls it *the recommended
selection*. It is a fine network to learn in. It is a poor one to build a company on, for one reason:

**every auto mode network has the same ranges.** Two of them cannot be joined by peering or by a VPN, lessons
18 and 21, because the same addresses would be on both sides. Neither can an auto mode network be joined to
an office whose network happens to use anything in `10.128.0.0/9`. An auto mode network can be converted to
custom mode once, and a custom mode network can never become auto again; the conversion keeps the ranges, so
it is a way out of the regions nobody uses, not out of the overlap.

The **default network** that a new project receives is an auto mode network named `default`, with firewall
rules that let it be reached on a few ports, lesson 16. The planner's organisation sets the boolean
constraint `compute.skipDefaultNetworkCreation`, lesson 4's machinery, so that its projects start with no
network at all and every network in them is one somebody wrote.

## The planner's network, written

Custom mode, a subnet in São Paulo and one in Santiago, and global routing, which decides how far routes
learned from outside reach, lesson 21. Replace `~/gcp/network/network.tf` with this, which has a mistake in
its last subnet:

```hcl
resource "google_compute_network" "planner" {
  project                 = "planner-dev"
  name                    = "planner"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "sao_paulo" {
  project       = "planner-dev"
  name          = "planner-sao-paulo"
  network       = google_compute_network.planner.id
  region        = "southamerica-east1"
  ip_cidr_range = "10.10.0.0/20"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }
}

resource "google_compute_subnetwork" "santiago" {
  project       = "planner-dev"
  name          = "Planner_Santiago"
  network       = google_compute_network.planner.id
  region        = "southamerica-west1"
  ip_cidr_range = "10.11.0.0/33"
}
```

```
ana@laptop:~/gcp/network$ terraform plan -input=false -no-color 2>&1 | grep -E "^Error"
Error: "name" ("Planner_Santiago") doesn't match regexp "^(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)$"
Error: "ip_cidr_range" is not a valid IP CIDR range: invalid CIDR address: 10.11.0.0/33
```

Two refusals from the provider, before anything is asked of Google: a subnet's name follows the same rule as
a network's, lowercase letters, digits and hyphens, and `/33` is not a prefix length at all. Change the name
to `planner-santiago` and the range to `10.11.0.0/20`, and plan again:

```
ana@laptop:~/gcp/network$ terraform plan -input=false -no-color | grep -E "^Plan:|# google|ip_cidr_range|auto_create|routing_mode"
  # google_compute_network.planner will be created
      + auto_create_subnetworks                   = false
      + routing_mode                              = "GLOBAL"
  # google_compute_subnetwork.santiago will be created
      + ip_cidr_range                    = "10.11.0.0/20"
  # google_compute_subnetwork.sao_paulo will be created
      + ip_cidr_range                    = "10.10.0.0/20"
          + ip_cidr_range = "10.20.0.0/16"
Plan: 3 to add, 0 to change, 0 to destroy.
```

Three resources: the network and its two subnets. The **secondary range** on the São Paulo subnet is a
second block of addresses for things that are not machines, the pods of a Kubernetes cluster being the usual
one; it belongs to the subnet, in the same region, and its addresses must not overlap anything either.
