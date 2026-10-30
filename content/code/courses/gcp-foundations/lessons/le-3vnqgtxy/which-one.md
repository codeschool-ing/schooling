---
title: Which one, and when
version: 1
---

**Shared VPC and peering answer two different questions.** Shared VPC answers *how do several teams of one
company use one network without sharing one project*. Peering answers *how do two networks that belong to
different owners talk*. Most companies the size of the planner use both, for different neighbours.

| | Shared VPC | VPC peering |
|---|---|---|
| how many networks | **one**, in the host project | **two**, each with its own owner |
| organisations | the same one | any |
| who runs the firewall | the host's network team, for everyone | each side, for its own machines |
| who agrees | the Shared VPC Admin attaches a project | **both** sides create the peering |
| overlapping ranges | impossible: it is one network | refused |
| transitive | not a question: everyone is in one network | **no** |
| billing | each service project pays for its own machines and their traffic | each side pays for its own machines and the traffic they send |

## The planner's estate, settled

- **Production and staging** are service projects of `planner-network`. One network team, one set of
  firewall rules, one list of ranges, lesson 15's rule of thumb kept in one place.
- **Development** keeps a network of its own in `planner-dev`, the one this course has been planning, so that
  developers can change its rules without asking the network team. It is not peered with production on
  purpose: nothing in development should be able to reach a production database, and a peering would be the
  first step towards it.
- **The partner** is peered with `planner-network`, with custom routes neither exported nor imported, and
  firewall rules on the planner's side that let the partner reach one service on one port.
- **The acquired company** waits. Its São Paulo range overlaps the planner's, so it is renumbered first and
  peered afterwards, or reached through something that translates addresses, which neither of these does.

## When neither is enough

Peering's refusal to be transitive becomes a problem at around the fifth network, when every pair that has
to talk needs a peering of its own and the list grows as the square of the networks. Google's answer to that
is **Network Connectivity Center**, a hub that networks attach to as spokes and through which they reach each
other, and it is where a company with many networks ends up. It is named here so that the moment it is
needed is recognised; the planner, with two neighbours, does not need it.
