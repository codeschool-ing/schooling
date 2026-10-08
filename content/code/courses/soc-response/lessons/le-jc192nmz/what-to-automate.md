---
title: What is worth automating
version: 1
---

**SOAR**, *security orchestration, automation and response*, is the name for the machinery that acts on
alerts: it receives one from the SIEM, runs a sequence of steps, and calls other systems (a firewall, a
directory, a ticketing tool, a messaging channel) through their interfaces. As with SIEM, the products
differ and the idea does not.

A common belief is that SOAR is about responding faster than a person can. **Most of its value is in the
boring part before the response**: gathering the same facts for the hundredth time, in the same order,
without forgetting one. The decision is usually still a person's. Five questions decide whether a step
belongs to a machine:

| question | automate when |
|---|---|
| **How often?** | it happens many times a week; a yearly task is cheaper by hand |
| **How much judgement?** | the same inputs always deserve the same output |
| **How reversible?** | a mistake can be undone in seconds, with nothing lost |
| **How wide?** | it touches one address, one host, one account, never a whole network |
| **How well understood?** | the team has done it by hand, the same way, often enough to write it down |

Enrichment passes all five, which is why it is the first thing every team automates. Blocking one
external address at the firewall passes most of them: frequent, narrow, reversible in one command.
Disabling an employee's account fails the second and the fourth, because it stops somebody's work and
the right call depends on who they are and what they were doing. Wiping a laptop fails nearly all of them.

The table has a sixth row nobody writes down: **automate only what you can measure**. A playbook that runs
four hundred times a month without anybody counting how often it was right is a source of incidents, not
a defence against them. The last section of this lesson comes back to that.
