---
title: "Public cloud: strangers on the same hardware"
version: 1
---

A public cloud is open to anybody who can sign up and pay. The provider owns the buildings, the
machines and the network, and **your workloads share them with other customers' workloads**. The
virtual machine you start in a public region runs on a physical server that is, at that moment,
almost certainly running machines that belong to somebody else. That is lesson 1's resource pooling
seen from the customer's chair, and it has a name: **multi-tenancy**. A tenant is one customer, and
multi-tenant means many of them on one set of hardware.

The wrong picture is that sharing the hardware means sharing the data, as if the neighbour on the
same server could open your disk or read your packets. Keeping tenants apart is the provider's
core product, and it does that in two layers.

## Two layers of isolation

The first layer is **the hypervisor**, the software that runs virtual machines on a physical host.
It gives each guest its own slice of memory, its own virtual disks and its own network interface,
and it refuses any attempt by one guest to reach into another. Lesson 4 looks at virtual machines
themselves; here it is enough that the boundary between two tenants on one host is software the
provider writes and patches.

The second layer is **software above the machine**. Every request to the provider's API is checked
against the identity that made it, so your credentials open your resources and nobody else's
(lesson 7). Every customer's network is a private network of its own, which carries no traffic to
or from another customer's unless one of them connects the two on purpose (lesson 6).

The boundary is strong, and it is not perfect. In January 2018 the attacks called Spectre and
Meltdown showed that a program could infer memory it was never allowed to read, through the way
processors speculate ahead of the instruction they are on. Providers patched hosts and hypervisors
across their fleets. For customers who must not share hardware at all, providers sell dedicated
options at a higher price — AWS calls them Dedicated Instances and Dedicated Hosts — which turns
multi-tenancy into a setting you pay to switch off.

## What you gain

The first gain is **capacity you never bought**. A hundred machines for one hour cost what one
machine costs for a hundred hours, because the list price is per hour of use. At the public list
price for a `t3.medium` in `sa-east-1`, 0.06720 USD an hour, a hundred of them for an hour of load testing is 6.72 USD, and
then they are gone.

Services nobody would build for one company come with it: managed databases, a DNS service with
servers around the world, regions on several continents. And the building, the power, the
cooling and the hardware refresh are the provider's problem.

## What you give up

- the choice of hardware and place: you pick a region and a machine type, not a rack or a supplier;
- the terms: prices, quotas and the life of a service are set by the provider, on its schedule,
  for every customer at once;
- predictable neighbours: a host shared with other tenants can deliver less than it did yesterday,
  because they are busy today;
- a free exit: data going out of the provider is **billed per gigabyte**, and the section on the seam
  works out how much.

And lesson 1's line still applies. The provider secures the hardware and the hypervisor; the
permissions, the network rules and the bucket left readable by the world are yours, however many
tenants share the host.
