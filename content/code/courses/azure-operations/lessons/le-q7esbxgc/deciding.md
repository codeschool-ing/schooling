---
title: The bill, and the decision
version: 1
---

**Which plan, if any, is arithmetic first and judgement second.** This course could not read the price
list (lesson 1 section 03), so the arithmetic uses **round illustrative figures** of the right shape, which
you replace with today's for your region:

- Network Protection: **3,000 USD a month** for a plan covering up to **100** public IPs, plus a charge per
  IP above that;
- IP Protection: **200 USD a month** for each protected IP.

At 200 USD each, IP Protection costs as much as the plan at 3,000 ÷ 200 = **15 protected IPs**. Below that,
IP Protection is cheaper; above it, the plan is, and the plan also brings rapid response and cost
protection, which have no price on the IP tier at all.

Then the judgement, in three questions:

1. **Which public IPs would be protected?** The shop's customer traffic enters through Front Door, which
   has its own edge protection and is not a public IP in the shop's virtual network. Its regional public
   IPs are a NAT gateway's outbound address and a bastion host: neither is how customers reach it.
2. **What does an hour of outage cost?** Lesson 14's error budget put a price on failures; if a flood
   against a regional IP would take orders down, that price is the comparison.
3. **Who would answer at 03:00?** Rapid response is worth most to a team without a network engineer on
   call.

For the shop, today, the answer is **neither plan**: its customer entry is Front Door, and its regional IPs
carry nothing customers depend on. That changes the day it puts a public Application Gateway in
`brazilsouth`, and the decision is written down with that condition, so the next person knows when to ask
again.
