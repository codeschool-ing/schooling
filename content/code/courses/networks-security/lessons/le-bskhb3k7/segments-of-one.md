---
title: Segments of one
version: 1
---

Lesson 4 drew zones and put a firewall between them; lesson 4 also found the flaw, that machines in the
same zone reach each other freely. **Microsegmentation** takes the idea to its end: every workload is
its own segment, and every connection between two workloads, even on the same switch, is allowed by a
rule or refused.

It cannot be done with the central firewall alone, because traffic inside a segment never crosses it.
It is done **on each machine**, with a host firewall like the ones lessons 9 and 19 wrote by hand, or in
the virtual switch of a hypervisor, or in a container platform's network policy. The mechanism differs;
the policy is the same shape.

What makes it manageable is **writing the policy once, by role, and generating each machine's rules
from it**. Nobody maintains two hundred hand-written host firewalls consistently; they maintain one
table of who may talk to whom, and a program writes the rules. Lesson 19's rule for `db` was written by
hand. This lesson writes it from a policy, for every server, and applies the same kind of rule to the
rest.

| | zones (lesson 4) | microsegmentation |
|---|---|---|
| the unit | a segment of many machines | one workload |
| enforced by | the firewall between segments | each host, or the hypervisor next to it |
| written as | a matrix of zones | a table of roles |
| inside a zone | open | closed unless a rule allows it |
| the cost | one policy on one box | a policy per workload, which only automation makes bearable |
