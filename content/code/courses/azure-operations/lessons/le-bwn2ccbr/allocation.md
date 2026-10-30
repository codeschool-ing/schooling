---
title: Cost allocation, and dividing what nobody can own
version: 1
---

**Some costs are genuinely shared**, and tagging them to one team would be a lie. The shop's Front Door
serves the shop's site and the export team's download links; the Log Analytics workspace holds both
teams' logs; the reservation of lesson 22 covers whatever matching VMs run. Three ways to handle them:

- **leave them in a shared bucket**, tagged `team: platform`, and report them as overhead. Honest, and it
  hides who drives the cost;
- **split them by a fixed share**, agreed in advance: Front Door 80% shop, 20% exports. Simple, and wrong
  as soon as usage moves;
- **split them by measured use**: the workspace's cost by each team's share of ingestion, which the
  `Usage` table of lesson 9 measures per table, and each table belongs to one team's resources.

**Cost Management's cost allocation rules** do the second and third inside the bill. A rule takes the cost
of named sources, such as a subscription, a resource group or a tag, and distributes it to targets in
proportion to their own cost, to fixed percentages, or evenly. The allocated cost then appears in the
targets' views as if they had spent it. Rules are set up at the billing scope and were **not run** here;
the measured split is a query over the cost export, the same shape as this lesson's.

Whatever the method, **write it down and keep it**. A split that changes every quarter makes every
month's comparison an argument, and the point of allocation is that each team can see the cost of its own
decisions, month after month, by the same rule.
