---
title: Conflict between teams is usually about a boundary
version: 1
---

**When two teams keep fighting, look for something they share that nobody owns.** Disagreements
between people come and go. Disagreements between teams recur, with different people, because the
cause is structural: a table both write to, a service both depend on, a release both have to
coordinate. Mediating each argument as it comes is necessary; fixing the boundary is what stops the
next one.

## Marola's three boundaries

Every conflict in this course so far has sat on one of three shared things:

1. **The orders database's connections**, shared by checkout and logistics until the quota.
2. **The table** that the route planner and the zone service both read and write, which lesson 7
   found behind five of seven incidents.
3. **Release timing**: logistics' batch jobs and checkout's peak, which nobody had written down as
   a constraint until 6 March.

Each one produced a conflict that looked personal ("checkout blames everybody", "logistics breaks
our releases") and was not. **The shared thing had no owner, so every decision about it was a
negotiation, and every negotiation was a chance to fall out.**

## Give every shared thing an owner and a contract

The structural fix has two parts:

- **An owner**: one team that decides changes to the shared thing, and must be consulted by the
  others. Not the team that shouts loudest; the one whose service would suffer most from a bad
  change. The orders database's connections now belong to the platform team.
- **A contract**: what the owner promises the others, in writing. The quota table is a contract.
  The outbox's event format, with a version number, is a contract. A contract turns "you broke us"
  into "the contract says X; did the change keep it?", which is a question with an answer.

Matthew Skelton and Manuel Pais, in *Team Topologies*, argue that teams should interact in a few
deliberate modes (collaborating closely for a while, providing a service to each other, or one team
helping another learn) and that most friction comes from interactions nobody chose. **Writing down
which mode two teams are in, and for how long**, is a cheap way to make an implicit boundary
explicit.

## The mediator is not the owner

Lívia mediated the quota conversation. She did not take ownership of the quotas, and she was careful
not to decide them herself, even though both leads would have accepted it. **A mediator who decides
becomes the next owner of the shared thing**, and then every future argument about it lands on her
desk, which does not scale past a handful of boundaries.

Her job was to get the two owners to a decision they both could live with, and to make sure the
decision had a home: the platform team for quotas, a decision record for the outbox.
