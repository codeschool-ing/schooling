---
title: "Private cloud: a datacentre is not one yet"
version: 1
---

A company has a room of servers running a hypervisor, a few hundred virtual machines on them, and
a slide that says *our private cloud*. It may be one. More often it is **a virtualised
datacentre**, and the difference is not the hardware. It is whether lesson 1's five
characteristics hold.

Take the usual arrangement, where a developer who needs a machine opens a ticket and an
administrator creates it two days later, and check it against the five:

| characteristic | the virtualised datacentre with a ticket queue |
|---|---|
| on-demand self-service | no: a person approves and builds every machine |
| broad network access | yes: it is reached over the company network |
| resource pooling | yes: the hypervisor cluster shares its hosts between teams |
| rapid elasticity | no: capacity changes when somebody schedules the work |
| measured service | rarely: nobody can say which team used how much |

Two of five. Virtualisation delivered the pooling, and **pooling is only one characteristic**.
The same room becomes a private cloud when a team can call an API or use a portal and have a
machine in minutes, with nobody approving each one. The pool has to grow and shrink on demand,
within the hardware it has. And usage has to be metered per team, even if nobody is charged for it
and the numbers only go into a report. That last practice is called *showback*, as opposed to a
*chargeback* that bills the team.

## What it is built from

The software that turns a room of servers into a private cloud is a stack with an API in front:
it takes requests, finds a host with room, creates the machine, the disk and the network, and
records who asked. **OpenStack** is the best-known open-source one. Stacks built on **VMware**'s
products are a common commercial choice, above all where a company already virtualised with them. Both
give the organisation's teams something that looks, from their side, like the IaaS of lesson 1.

## On premises, or hosted

NIST lets a private cloud stand anywhere, and both arrangements are common:

- on premises: the organisation's own building, its own staff, its own hardware;
- hosted: hardware dedicated to one customer in a provider's or a colocation company's
  datacentre, often operated by that provider under contract.

Both are private in the sense that matters: one organisation's workloads on that hardware. The
hosted version moves the building, the power and often the operations out of the company. It
does not move the ceiling.

## The ceiling is what you bought

Elasticity in a private cloud is **elasticity inside a fixed pool**. If the pool has 400 cores and
the month-end batch wants 600, the portal answers with a refusal or a queue, however good the
automation is. More capacity is a purchase order, a delivery and a day of racking, measured in
weeks rather than minutes.

So a company sizes a private cloud for its peak, plus the growth expected before the next purchase, plus
a spare margin, and most of that sits idle outside the peak. **Idle capacity is the price of
control**, and it is paid whether or not anybody uses it. A public region has the same idle
capacity, spread across all its customers; that sharing is exactly what a private cloud gives up.

That does not make it a mistake. The reasons that hold up are specific: data or rules that forbid
shared hardware, loads so steady that the idle margin stays small, systems on the premises that
need to be a few metres away, and hardware and people the company already has. The section on
repatriation puts numbers on the second of those; the rest are in the table at the end of the lesson.
