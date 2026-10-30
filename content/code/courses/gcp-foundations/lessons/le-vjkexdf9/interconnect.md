---
title: Cloud Interconnect, the private road
version: 1
---

**Cloud Interconnect replaces the internet between the datacentre and Google with a circuit.** Traffic does not
cross the public internet at all, it is not encrypted by Google by default because it does not need to be in
the way a VPN's is, and its bandwidth and latency are those of the circuit rather than of whatever the office's
provider happens to deliver that afternoon. It is what a company moves to when the VPN is full, or when the
data that crosses it is large enough for the cheaper transfer price to matter.

There are two ways to get one:

| | Dedicated Interconnect | Partner Interconnect |
|---|---|---|
| what it is | a physical cable from the company's router to Google's, in a colocation facility both are in | a connection through a service provider that is already connected to Google |
| capacity | circuits of 10, 100 or 400 Gbps | attachments from 50 Mbps to 50 Gbps |
| who needs it | a company with its own equipment in one of Google's colocation facilities | everybody else |

**The VLAN attachment** is the piece inside Google Cloud either way: it ties a connection to a Cloud Router in
one region of one VPC network, and the router speaks BGP over it exactly as it does over an HA VPN tunnel. The
office's routes arrive as dynamic routes, the planner's subnets are announced to the office, and nothing in
the network above the router knows whether the routes came by VPN or by circuit.

**Cross-Cloud Interconnect** is the same thing with another cloud at the other end of the cable, for the
company whose data lives in one provider and whose computing lives in another.

## Encryption over a circuit

A circuit is private, which is not the same as encrypted: the traffic on it can be read by anyone with access
to the cable or the provider's equipment. Two answers exist, and the planner's security team chooses one
before the first byte of customer data crosses:

- **MACsec** on Dedicated Interconnect, which encrypts each frame on the link between the company's router and
  Google's;
- **HA VPN over Cloud Interconnect**, which runs IPsec tunnels through the attachment, so the circuit carries
  only encrypted traffic, at the cost of the VPN's own limits per tunnel.

## Nothing to run

Interconnect cannot be run in the lab or planned meaningfully without one: a connection is ordered, a letter
of authorisation is issued to the colocation facility, and somebody connects a cable. The Terraform resources
exist, `google_compute_interconnect_attachment` among them, and they describe the half that is software once
the half that is physical is done. That half is weeks of lead time, which is the first thing to know about it
when a project's schedule depends on it.
