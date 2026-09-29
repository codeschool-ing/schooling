---
title: "A VPC: a network of your own inside theirs"
version: 1
---

The picture most people arrive with is that a machine in the cloud sits on the internet, the way a
server in a data centre once sat on a public address with a cable to the world. It does not. A
virtual machine from lesson 4 is plugged into a network, and **that network is one you define**: its
addresses, how it is divided, what may leave it and what may come in. The provider calls it a
**virtual private cloud**, a VPC. Azure calls the same thing a virtual network, or VNet, and Google
Cloud a VPC network.

It is private in a precise sense. The provider runs one enormous physical network, and every
customer's VPC is carved out of it in software. Two customers can both use `10.0.0.0/16` inside
their VPCs, in the same region, on the same racks, and neither sees a packet of the other's. Nothing
reaches a machine in your VPC from outside unless you built a path for it, and the rest of this
lesson is those paths: the route to an internet gateway, a NAT gateway, a load balancer, a peering.

**A VPC lives in one region** on AWS and Azure, and spans that region's zones (lesson 9 says what a
zone is, and why it matters). Google Cloud is the exception worth knowing: its VPC network is
global, and only its subnets belong to a region.

## The addresses are yours to choose

When you create a VPC, you give it a range of addresses. Nobody on the internet will ever see them,
so they come from the three ranges set aside for private networks by RFC 1918, the same ranges your
home router hands out:

| range | first address | last address |
|---|---|---|
| `10.0.0.0/8` | `10.0.0.0` | `10.255.255.255` |
| `172.16.0.0/12` | `172.16.0.0` | `172.31.255.255` |
| `192.168.0.0/16` | `192.168.0.0` | `192.168.255.255` |

::: track networks-infra
You met this notation in `networks-addressing`, and the next section is the part of it a VPC uses,
with the provider's vocabulary added: read it as revision, and slow down where it reaches the
addresses a provider keeps for itself.
:::

::: track *
The number after the slash is the size of the block, read backwards: the smaller it is, the bigger
the block. The next section is how to read it, and it is all the subnetting this course needs.
:::

A common choice is a `/16` out of `10.0.0.0/8`, such as `10.0.0.0/16`: large enough to divide into
many subnets, small enough that you can give each VPC a different one.

## Why the choice matters on the day you connect two networks

**Two networks whose ranges overlap cannot be joined.** A peering between two VPCs, or a VPN from a
VPC to the office (lesson 2's hybrid seam), is refused or unusable. A router handed a packet for
`10.0.5.9` has to decide which side that address is on, and with overlapping ranges it is on both.

This happens for real. Every AWS region gives each account a **default VPC**, created for you,
and its range is `172.31.0.0/16` in every account and every region. Two teams that each built on
their default VPC have two networks with the same range, and on the day somebody asks for them to
talk to each other, the answer is a migration.

So the choice is made once, early, with a list in hand: the office's range, every other VPC you
have or will have, the network of any partner you might connect to. Give each a range of its own,
for example `10.0.0.0/16` for production, `10.1.0.0/16` for staging and something well away from
both for the office. **On AWS the range a VPC was created with cannot be changed** afterwards; you
can add further ranges to it, and that is all. Getting it wrong costs nothing on day one, which is
exactly why people get it wrong.
