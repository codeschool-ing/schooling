---
title: What happens when the budget runs out
version: 1
---

A budget is only useful if spending it changes something. **The error budget policy says what, and
it is agreed before it is needed**, by the people who build features and the people who answer the
pager, because on the day it applies they will want opposite things.

A typical policy has three levels:

| budget left in the window | what the team does |
|---|---|
| plenty | releases as usual; experiments and risky migrations are fine |
| under a quarter | releases need a rollback plan; the next sprint carries one reliability item |
| none | only fixes and reliability work ship until the budget recovers |

Three properties make it work:

- **It is mechanical.** The number decides, not a debate in a meeting. A freeze that needs
  somebody's approval every time is a freeze that does not happen.
- **It works in both directions.** A budget that is never spent says the objective is too loose,
  or the team is too cautious: it could release faster, run that migration, or turn off the
  expensive redundancy nobody needed. Unspent budget is wasted speed.
- **It has exceptions written down.** A security fix ships whatever the budget says, and an outage
  caused by a provider everybody depends on may be excluded, but only if the policy says so in
  advance.

What the policy is *not* is a punishment. It does not say who spent the budget, and the postmortem
of lesson 18 is the place to understand why it was spent. **It is a rule about pace, not about
people**: when the system has been unreliable lately, the next changes are made more carefully.
