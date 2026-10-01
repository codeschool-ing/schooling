---
title: When a typed route is the right answer
version: 1
---

A **static route** is one line in a routing table that a person wrote: *to reach this network, hand
the packet to that neighbour*. Nothing on the router produced it and nothing will change it. It stays
exactly as typed until somebody types again.

The common picture is that static routing is the beginner's version, the thing you do until you learn
OSPF. That picture is wrong about where static routes live. **Almost every computer you have ever used
runs static routing**: the default gateway lesson 14 read on a PC is a static route, typed by an
administrator or handed over by DHCP, and the PC never discusses it with anybody. Most routers on the
edge of the internet are the same. A branch office with one link to head office, a home router with one
link to its provider, and the provider's own route pointing a customer's block down that customer's
cable are all static, and all of them are right.

## What you get for typing it

- **Predictability.** The table holds what the engineer wrote and nothing else. When a packet goes the
  wrong way, the reason is a line you can read, not the outcome of a protocol's calculation.
- **Nothing to attack and nothing to misconfigure on the wire.** A routing protocol listens to its
  neighbours, so a neighbour that lies, or a mistake on another router, can rewrite this router's
  table. A static route listens to nobody.
- **No cost.** No messages, no timers, no memory for a neighbour's database.
- **It wins.** Lesson 14 put the administrative distance of a static route at 1, below every routing
  protocol, so a typed route beats a learned one for the same prefix. That is useful when you mean it
  and a trap when you forgot it was there.

## What it costs

**Every change is made by hand, on every router the traffic crosses.** In this lesson's lab, joining
two networks across three routers takes four routes: two towards the far network and two back. A
fourth network would mean visiting every router again. The work grows with the number of networks and
the number of routers together, which is why nobody runs a large network this way.

**A static route notices only its own router's cables.** If the cable plugged into this router loses its
signal, the router stops using the routes through it. If a cable two routers away fails, nothing here
changes, and packets keep going towards the break. The section on floating routes shows that happening
in the lab, and lesson 16 is the answer to it.

## The rule of thumb

| situation | static fits? |
|---|---|
| one way in and one way out: a branch, a home, a host | yes, a default route is all it needs |
| a fixed link to a partner's network, rarely changed | yes |
| two paths, where the backup is only for when your own cable fails | yes, with a floating route |
| several routers, several paths, failures you must route around | no, run a routing protocol |

**Static where there is one way to go, dynamic where there is a choice.** The rest of this lesson types
the routes into a lab of three routers, finds out what every route needs that a beginner forgets, and
then breaks a cable to find the edge of what typing can do.
