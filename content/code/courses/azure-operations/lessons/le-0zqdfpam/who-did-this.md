---
title: Answering "who did this?"
version: 1
---

**Three questions arrive every week, and each is one query.** The first: *who deleted something?*

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | where OperationNameValue endswith "/DELETE" | project TimeGenerated, Caller, CallerIpAddress, ResourceGroup, Resource'
TimeGenerated         Caller           CallerIpAddress  ResourceGroup  Resource
2026-10-17T21:12:00Z  ana@example.com  203.0.113.24     rg-test-ana    sttestana01
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | where Resource startswith "sql-shop" | project TimeGenerated, Caller, ActivityStatusValue, sku = tostring(Properties.sku), before = tostring(Properties.previousSku)'
TimeGenerated         Caller             ActivityStatusValue  sku  before
2026-10-15T16:58:00Z  bruno@example.com  Failure              S1
2026-10-15T17:02:00Z  bruno@example.com  Success              S1   S3
2026-10-15T17:44:00Z  carla@example.com  Success              S3   S1
```

One deletion, a test storage account in `rg-test-ana`, by `ana`, on Saturday evening. The second query
answers the question lesson 15 needed: everything that happened to the database, in order, with the SKU
before and after, read out of `Properties` with `tostring()`. A dynamic value has to be given a
type before it can be compared or displayed as text.

The second question: *what has each identity been doing?*

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | summarize changes = count(), failed = countif(ActivityStatusValue == "Failure"), operations = make_set(tostring(split(OperationNameValue, "/")[-1])) by Caller | order by changes desc'
Caller                                changes  failed  operations
3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11  6        0       ['WRITE', 'ACTION']
ana@example.com                       3        0       ['WRITE', 'DELETE']
bruno@example.com                     2        1       ['WRITE']
carla@example.com                     1        0       ['WRITE']
```

`make_set()` collects the distinct values of an expression into an array, and `split(...)[-1]` takes the
last part of the operation name. The pipeline's identity made six changes, all writes and actions, which
is what a pipeline should do. **A person appearing near the top of this list is worth a look**, not
because people should not change things, but because every change a person makes in the portal is a
change no pull request reviewed.

The third: *who changed who has access?*

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | where OperationNameValue startswith "MICROSOFT.AUTHORIZATION/" | project TimeGenerated, Caller, OperationNameValue, Properties'
TimeGenerated         Caller           OperationNameValue                             Properties
2026-10-13T18:40:00Z  ana@example.com  MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE  {'role': 'Monitoring Reader', 'principal': 'carla@example.com'}
2026-10-15T16:59:00Z  ana@example.com  MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE  {'role': 'SQL DB Contributor', 'principal': 'bruno@example.com'}
```

Two role assignments, both by `ana`. The second is the one lesson 15's postmortem found: at 13:59 on
Thursday, a minute after Bruno was refused, `ana` gave him *SQL DB Contributor* on `rg-shop`, and the
database could be resized from the portal. Nobody did anything wrong in a way a rule forbids, which is
exactly why the postmortem's action was to put the database's size in Bicep, and why role assignments get
an alert in the next section.
