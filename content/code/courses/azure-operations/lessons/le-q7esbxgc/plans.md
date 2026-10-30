---
title: The two paid plans, and what they add
version: 1
---

**Azure DDoS Protection has two paid tiers**, and they differ in what they are attached to and how they are
billed, not much in what they detect:

| | **DDoS Network Protection** | **DDoS IP Protection** |
|---|---|---|
| attached to | a **DDoS protection plan**, linked to virtual networks; every public IP in them is covered | each public IP, one by one |
| billed | a fixed monthly fee for the plan, covering a set number of public IPs, plus a charge per extra IP | per protected IP, per month |
| rapid response team and cost protection | included | not included |

What both add over the free infrastructure protection:

- **adaptive tuning**: thresholds learned from your own traffic, so an attack is detected at the volume
  that hurts *you*;
- **telemetry and alerts**: metrics such as *under DDoS attack or not* per public IP, and mitigation
  reports and flow logs through diagnostic settings, which the alerts of lesson 12 can watch;
- with Network Protection, **DDoS rapid response**, Microsoft's team to call during an active attack, and
  **cost protection**, a credit for the scale-out costs an attack caused.

None of this can be turned on without a subscription, so **nothing in this lesson was run**. The plan is
one resource and one property on each virtual network, the sort of Bicep the earlier lessons compiled;
writing it here would add nothing, and the decision is the interesting part.
