---
title: "Repatriation: moving back out"
version: 1
---

*Repatriation* is moving workloads out of a public cloud and back onto hardware the company owns
or leases, in its own building or in a colocation facility. Two opposite wrong pictures surround
it. One says the cloud is always cheaper, because somebody else buys the hardware. The other says
companies are leaving the cloud because it turned out to be a swindle. **Neither is about the
workload**, and the workload is what decides.

## The shape of the load

An on-demand price pays for more than the machine. It pays for the provider keeping capacity
ready for customers who have not arrived yet, and for letting you hand the machine back after an
hour. A load that is **spiky** uses that: the hundred machines of the load test, the Black Friday
week, the month-end batch. A load that is **steady** — the same machines, busy around the clock,
every day, for years — pays for a flexibility it never uses.

The provider's own answer to a steady load comes first, and it is on the sheet. For an `m7i.large`
in `sa-east-1`, with a month taken as 730 hours:

- on demand: 0.16065 × 730 = 117.27 USD a month;
- 1-year reserved, no upfront: 0.09956 × 730 = 72.68 USD a month;
- the saving: 1 − 0.09956 / 0.16065 = 0.38, so the commitment costs 38% less.

A year's commitment takes off more than a third, with no hardware bought. So the honest
repatriation question is not "owned hardware against the on-demand price". It is **owned hardware
against the committed price**, and lesson 10 covers commitments and the other billing models.

## The costs people forget

The spreadsheet that makes repatriation look easy puts the purchase price of a server next to a
year of the cloud bill. What that leaves out:

- the people: somebody installs, patches and replaces the hardware, the storage and the network,
  and somebody is on call at three in the morning when a disk fails;
- the building: power, cooling, space and physical security, or the colocation fees that stand in
  for them;
- the refresh: hardware is replaced every few years, so the purchase is a recurring cost spread
  thinly, not a one-off;
- capacity planning: you buy for the peak, plus growth, plus a spare, months ahead, and a wrong
  forecast is either idle metal or a shortage with no quick fix;
- the managed services: a managed database becomes a database your team runs, with its backups,
  upgrades and failover;
- the move itself: the data has to come out, at the egress prices of the section on the seam — 50 TB out of
  `sa-east-1` was 7,188.48 USD in a single month.

## When it wins, and when it loses

It can win for a load that is large, steady and well understood, run by a team that already
operates hardware, with few managed services underneath it. It can win on bandwidth too: a service
sending 200 TB a month to the internet from `sa-east-1` pays 25,927.68 USD for the transfer alone,
every month, while bandwidth bought for a datacentre is usually sold by capacity rather than per
gigabyte moved.

It loses for loads that are small, spiky or growing fast, for teams with nobody to run hardware,
and for applications built on the provider's managed services, where leaving means rebuilding them.
**Repatriation is a decision per workload**, not a verdict on the cloud. A company can move one
steady system back and keep everything else exactly where it was.
