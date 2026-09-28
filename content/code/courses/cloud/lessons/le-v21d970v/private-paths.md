---
title: "Private paths: reaching things without the internet"
version: 1
---

Everything so far leaves the VPC by the internet gateway, directly or through a NAT gateway. Three
kinds of traffic have a better way out, and each is a subject of its own in the vendor courses;
what you need here is to recognise them and know what each one is for.

## Endpoints, for the provider's own services

A private instance that writes to the provider's object storage (lesson 5) would, by default, go
out through the NAT gateway to the storage service's public address, paying the NAT section's
processing charge on every gigabyte to reach a service in the same region. **An endpoint is a
private path from the VPC to a provider service.** AWS has two kinds. A gateway endpoint is a route
in the subnet's route table that points the service's address ranges at the endpoint; it exists for
S3 and DynamoDB, at no charge. An interface endpoint is a network interface with a private address in
your own subnet, for most other services, billed by the hour and by the gigabyte.
Google Cloud's Private Google Access and Azure's private endpoints answer the same need. A backup
job that copies terabytes to object storage every night is the case where the difference shows up
on the bill.

## Peering, between two VPCs

**VPC peering joins two VPCs** so that instances in each reach the other by private address, with a
route in each side's tables pointing the other's range at the peering. It is the case the first
section of this lesson prepared for: the ranges must not overlap. On AWS a peering is also not
transitive. If A is peered with B and B with C, A still cannot reach C through B: it needs a peering
of its own. Past a handful of VPCs the providers offer a hub that every VPC attaches to instead,
which on AWS is the transit gateway.

## A VPN or a dedicated link, to the office

The hybrid cloud of lesson 2 needs a path between the VPC and a network you own. **A site-to-site
VPN** is an encrypted tunnel over the internet between a gateway on the provider's side and a
router at the office: quick to set up and bounded by the internet's quality on the day. A
dedicated link is a private circuit from your premises, or a data centre you rent space in, into the
provider's network: AWS Direct Connect, Azure ExpressRoute, Google Cloud Interconnect. It takes
weeks to order and gives predictable bandwidth and latency. Both need the office's range and the
VPC's range to be different, which is the reason the choice in the first section was made with the
office's range in hand.

How each one is configured, what it costs and where its limits are belongs to `aws-foundations`,
`azure-foundations` and `gcp-foundations`; how they are secured belongs to `cloud-security`.
