---
title: What it costs, and what to measure
version: 1
---

**A WAF is billed for the policy, for each rule, and for the requests it inspects**, and the shape of the
bill differs between the two places. On Front Door, the WAF comes with the Premium tier's price and its
per-request charges; on Application Gateway, the WAF is a tier of the gateway itself, billed per hour and
per unit of capacity. This course could not read the price list (lesson 1 section 03), so it gives no
figures; the shape is what to plan with.

What a team should measure once the WAF is running is not the number of blocks, which mostly counts
scanners and says nothing about safety. It is three things:

- **false positives**: legitimate requests blocked, found by the customer reports and by the 403s on
  routes customers use. Each one is a lost sale;
- **custom-rule hits**: how often `checkoutRateLimit` fires, and from where. A sudden rise is somebody
  trying, and worth a look even though the rule held;
- **rules in Detection**: anything still not blocking, and why. A policy left in Detection for a year is
  a log, not a firewall.

None of these numbers exists in the lab. All three are queries on the WAF's log table, written in the KQL
of lesson 10 once the logs exist.
