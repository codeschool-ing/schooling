---
title: Advisor, the same question asked by Azure
version: 1
---

**Azure Advisor runs these checks for you, continuously, and lists what it finds** as cost recommendations:
*right-size or shut down underutilised virtual machines*, *delete unattached disks*, *delete unassociated
public IPs*, and several more for databases, App Service and reservations. It is free, and it reads the
same signals: platform metrics for CPU and network, Resource Graph for what is attached to what.

Advisor's VM rule is documented as a configurable threshold: a VM whose CPU stays under a percentage you
choose, over a window you choose, is flagged, and Advisor suggests a smaller size in the same family, with
an estimated saving. It also proposes **reservations**, lesson 22's purchase, from your recent usage.
None of it was run here: Advisor lives in a subscription.

Two reasons the shop still writes its own queries. **It can read them**: an Advisor recommendation is a
conclusion, and a query is the reasoning, which matters when the owner of the VM disagrees. And **it can
add what Advisor does not know**, such as the `owner` tag or a list of VMs that must keep their size for a
licence. Advisor is where to start; a query is how to argue.

One more query explains `vm-reports`:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'Perf | where Computer == "vm-reports" | summarize max_cpu = max(CounterValue), hours_over_5 = countif(CounterValue > 5)'
max_cpu  hours_over_5
2.0      0
```

Its CPU never passed 2% in two weeks. Advisor would say *shut it down*, and it would be right for these two
weeks. The owner, when found, will say it runs the month-end reports on the last two days of the month,
which these two weeks do not contain. That is the reason the next section exists.
