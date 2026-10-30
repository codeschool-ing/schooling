---
title: What a record holds
version: 1
---

**The activity log records control-plane operations: requests to Resource Manager that create, change or
delete something, and some actions on resources.** It does not record data-plane operations: reading a
blob, querying a database or fetching a secret are not in it; those are in each service's resource logs,
lesson 8's diagnostic settings. That boundary decides what this lesson can answer: *who deleted the
storage account* is in the activity log; *who read the file in it* is not.

Lesson 15 loaded twelve of the week's records, written by the course in the shape of the `AzureActivity`
table, with one row per completed operation. Load `activity.kql` again if the emulator restarted. One of
them, whole:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AzureActivity | where Resource == "sttestana01"'
TimeGenerated         OperationNameValue                        ActivityStatusValue  Caller           CallerIpAddress  ResourceGroup  Resource     Properties
2026-10-17T21:12:00Z  MICROSOFT.STORAGE/STORAGEACCOUNTS/DELETE  Success              ana@example.com  203.0.113.24     rg-test-ana    sttestana01  {}
```

The columns that answer questions:

- **`OperationNameValue`**: the operation, as the resource provider names it, ending in `WRITE`, `DELETE`
  or `ACTION`;
- **`ActivityStatusValue`**: in the real table an operation writes several rows, `Start`, `Accepted`,
  then `Success` or `Failure`; the course keeps the final one;
- **`Caller`**: the user principal name for a person, or an object or application id for a service
  principal or managed identity, which is why the pipeline appears as a GUID;
- **`CallerIpAddress`**: where a person called from; empty for Azure's own services;
- **`Properties`**: what else the provider wrote, a dynamic column, such as the new SKU.

The real table has more, including `CorrelationId`, which ties the rows of one operation together, and
`Authorization`, with the role that permitted it.
