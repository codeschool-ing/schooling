---
title: Choosing the protection, and what none of it covers
version: 1
---

The easy conclusion from the last three sections is that zones are better, so everything should use
them, and that a machine spread across zones is a machine that stays up. The first half is the
right default and the wrong rule. The second half is false. **Each arrangement buys survival of one
size of failure, and none of them survives a failure that every copy shares.** Choosing is a matter
of naming the failure, and then reading the table.

## What each one survives

| when this fails | one machine | availability set | across zones |
|---|---|---|---|
| a host | down | survives | survives |
| a rack's power or switch | down | survives | survives |
| a maintenance reboot | down for the reboot | survives, one update domain at a time | survives |
| a datacentre | down | **down**, if the set's racks are in it | survives |
| the region | down | down | down |
| a bad release, deployed everywhere | down | down | down |
| a bug in the shop's own code | down | down | down |

Two rows deserve a sentence each. Microsoft's overview of availability sets says plainly that they
remain exposed to failures of shared infrastructure, such as a network outage across a datacentre,
which can reach several fault domains at once. And for the maintenance row across zones, the page
on maintenance says updates that need no reboot are mostly sequenced zone by zone, with some
overlap at the end: the zones are not touched at the same moment, which is a different thing from
never being touched.

## The default, and its two exceptions

**In a region with zones, spread across zones.** Microsoft's own advice, read on 2026-10-30, is to
use a Flexible scale set for availability, and to spread it across zones for most workloads. That
is what lesson 4 did for the shop's order API, three instances in three zones of Brazil South. It
earns the 99.99% of the last section, and it is the only arrangement in this lesson that keeps the
shop up when one building goes dark.

The price is not a line on the bill for the zones themselves. It is three things you pay anyway.
At least two machines where one would do, which every arrangement here costs. A
little latency between machines in different zones, under two milliseconds of round trip but more
than between two racks in one building. And capacity: a size is not always offered in every zone,
which is what lesson 1's `az vm list-skus` shows per zone against a real subscription.

The two exceptions:

- An availability set, where there are no zones or where latency between machines matters more
  than surviving a datacentre. The overview says sets are especially useful in regions without
  zones, and that their machines are closer together than zones allow. A pair of machines
  replicating a database synchronously is the kind of work that fits. A set cannot also be given
  zones, as the compiler failed to notice two sections ago. And a regional Flexible scale set
  spreads across fault domains as well, which is why the same overview recommends the scale set
  first.
- One machine, for work that can wait. The shop's nightly sales report runs once, at night, and
  nobody reads it until the morning. If its host fails at two and the machine is back by half
  past, the report is late and nothing else happens. One machine on Premium SSD is promised 99.9%,
  forty-three minutes in thirty days, and a report that tolerates a late night does not need more.

A **proximity placement group** belongs to the first exception at its extreme: machines that need
the lowest latency between them, at the price of sitting in one datacentre. It is the right tool
for a tier that talks to another tier many times for every request, and the wrong one for
anything whose reason to exist is surviving that datacentre.

## What none of them protects against

**A region.** Every arrangement in this lesson is inside one, and a region that is unreachable
takes all of them with it. Surviving that means a copy in a second region, and `azure-foundations`
lesson 1 says which region each one is paired with. One detail of the pairs matters to this shop:
Microsoft's page on regions says a pair keeps data inside the same geography, **except for Brazil
South**, so a copy kept in Brazil South's pair leaves Brazil. Lesson 2 kept one replica of the
shop's image in South Central US so that machines could be recreated there. The image is the easy
part, and the orders are the hard one.

**A bad release.** The machines in three zones run the same image, and a deployment that breaks
it breaks it in three zones. What limits that is how many machines a change reaches at once, which
is lesson 4's rolling upgrade with its health check: a batch of instances at a time, stopped when
too many of them fail.

**A bug, or a mistake.** The copies run the same code, so a crash on a particular order crashes
every copy that receives one. A deleted resource group deletes every zone's machines in one
command. Neither is a failure of Microsoft's hardware, and the agreement says so: it excludes what
results from faulty input, and the operations you start yourself.

**Data that lives on one machine.** A machine's disk is in the machine's zone. A zone-redundant
disk, the `ZRS` kind of lesson 3, keeps three copies in three zones and is still reachable when one
zone is not, which is how a single machine's data survives the loss of its zone. It does not
protect against the release that wrote the wrong thing to it, which is a backup's job.

## The shop, decided

Put together, the shop ends up with two answers and a list. The order API is lesson
4's scale set across three zones, behind a Standard load balancer and a zone-redundant address,
because a lunchtime lost to a building is the failure that costs money. The nightly report is one
machine on Premium SSD, because it can wait. And what neither arrangement covers, a region, a
release and the shop's own code, is written down as the next things to solve, rather than assumed
to be covered by a percentage that never claimed to cover them.
