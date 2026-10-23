---
title: Hybrid links, and the inside that grew
version: 1
---

**A hybrid link joins a cloud network to a company's own, so that machines on each side reach the
other by private address. The security consequence is that both sides' idea of "inside" now
includes the other side, all of it, unless somebody narrows it on purpose.** Nothing in this section
was run: moto stores a VPN connection as a record and carries no traffic, so what follows is taken
from the providers' documentation.

## Three kinds of link

| link | AWS | Azure | Google Cloud |
|---|---|---|---|
| an encrypted tunnel over the internet | Site-to-Site VPN | VPN Gateway | Cloud VPN |
| a private circuit through a provider's facility | Direct Connect | ExpressRoute | Cloud Interconnect |
| the company's directory, extended to the cloud | IAM Identity Center with an external identity provider | Microsoft Entra Connect, syncing Active Directory to Entra ID | Google Cloud Directory Sync, or federation with Entra ID or another provider |

The first two join networks; the third joins identities, and it is a seam too.

## What goes wrong at a network link

**A rule that trusted "the office" now trusts the whole office.** Before the link, a security group
allowing `10.0.0.0/8` admitted the cloud's own machines. After it, the same rule admits every laptop,
printer and forgotten test server on the company network, because they share the range. A
compromised machine in the office is now one hop from the database. Name the narrow ranges the
cloud side actually needs to hear from, and nothing wider.

**Routes arrive without anybody changing the cloud.** A link that exchanges routes dynamically, over
BGP, can add the routes it learns to the cloud's route tables on its own: AWS calls this route
propagation, and it is a setting on each route table. A network the data centre team adds next year
then appears inside the VPC with no change on the AWS side at all. Lesson 8 reads route tables; a
propagated route is the kind of entry that review should be looking for.

**A private circuit is private, which is not the same as encrypted.** AWS's documentation says that
Direct Connect does not encrypt traffic in transit by default. The circuit avoids the public
internet, and the data on it is readable by anything on its path unless you add encryption, either
the link-layer encryption some dedicated connections support or a VPN tunnel run over the circuit.
Lesson 11 is about encryption in transit.

**The link is a boundary, so treat it as one.** A firewall on the link, with rules in both
directions, turns "everything on the other side" back into a list someone wrote.

## What goes wrong at an identity link

When the company directory feeds the cloud's, **the cloud's accounts are only as safe as the
directory**. Whoever can change a synced user or add someone to a synced group on premises can grant
access in the cloud, without touching the cloud. Microsoft's guidance for Entra ID is to keep the
accounts that hold its administrative roles cloud-only rather than synced, so that taking over the
on-premises directory does not hand over the cloud's administration as well.

The reverse also holds: **removing a person has to happen in the place that is the source**. A
leaver disabled in the cloud console but still active in the on-premises directory comes back at the
next sync. Lesson 6 follows a leaver whose access nobody revoked.

## A review for any seam

Four questions, one for each thing that crosses, cover the seams of this lesson and most others:

1. **Identity:** does any secret from one side live on the other? Replace it with federation.
2. **Route:** which ranges does each side accept from the other, and who decided them?
3. **Record:** can one action that crossed be followed from one side's logs into the other's?
4. **Policy:** for each control decided once, is it enforced on both sides, and how do you know?
