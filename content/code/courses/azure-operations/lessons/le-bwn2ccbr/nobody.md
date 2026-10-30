---
title: The resource nobody owns
version: 1
---

**Untagged spend is where waste hides, because nobody is ever asked about it.** The shop's thirty days of
it, by resource:

```kql
// nobody.kql: thirty days of spend with no team tag, by resource
CostDaily
| where Date >= datetime(2026-09-19)
| where isempty(tostring(Tags.team))
| summarize cost = round(sum(Cost), 2) by ResourceGroup, ResourceName, MeterCategory
| order by cost desc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < nobody.kql
ResourceGroup  ResourceName  MeterCategory     cost
rg-reports     vm-reports    Virtual Machines  144.27
rg-test-ana    disk-old-1    Storage           39.09
rg-test-ana    disk-old-2    Storage           20.96
rg-test-ana    pip-test      Virtual Network   3.6
```

Four resources and two groups. `vm-reports` is lesson 23's month-end VM, real and needed, and simply never
tagged; the fix is a tag, `team: finance`, once its owner said whose it was. Everything else is
`rg-test-ana`, the test group lesson 23 found idle: two disks and a public IP, still billed every day a
month after anybody used them. The share as a single number:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'CostDaily | where Date >= datetime(2026-09-19) | summarize total = sum(Cost), untagged = sumif(Cost, isempty(tostring(Tags.team))) | extend untagged_pct = round(100.0 * untagged / total, 1), total = round(total, 2), untagged = round(untagged, 2)'
total   untagged  untagged_pct
2556.9  207.92    8.1
```

Eight per cent of the month belongs to nobody. That number is the one the shop tracks, monthly,
and its target is not zero, which no organisation reaches, but **down**: every month the untagged share
should be smaller, and every resource in it should have been asked about.

The tag policies of the first section stop new untagged groups, which is the source of the problem.
`rg-test-ana` predates them, which is why it is here: a policy changes the future, and a query like this
one is how the past is found.
