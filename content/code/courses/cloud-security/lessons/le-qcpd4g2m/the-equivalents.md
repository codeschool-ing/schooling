---
title: The same record at Azure and Google Cloud
version: 1
---

**Every large provider records calls to its management API by default and leaves the reading of data
off by default.** The names differ and so do the defaults at the edges, and the edges are where an
investigation runs out of records. Lesson 5 set the three providers side by side in general; this
section does it for audit logs. Nothing in it was run here: it comes from Microsoft's and Google's
documentation.

| the question | AWS | Azure | Google Cloud |
|---|---|---|---|
| who changed a resource's configuration | CloudTrail management events | the **Activity Log**, per subscription | **Admin Activity** audit logs |
| who read or wrote the data inside a resource | CloudTrail data events, chosen per resource | **resource logs**, chosen per resource with a diagnostic setting | **Data Access** audit logs |
| who signed in, and how | CloudTrail, `ConsoleLogin` and the federation calls | **Microsoft Entra ID** sign-in logs and audit logs | Cloud Audit Logs, plus the sign-in records of the identity provider in use |
| kept with no setup | 90 days of management events, as event history | 90 days of Activity Log | Admin Activity for 400 days |
| kept longer | a trail, into a bucket you keep | a diagnostic setting, into a Log Analytics workspace, a storage account or an event hub | a log sink, into a bucket, BigQuery or another project |

## Azure

The **Activity Log** records control-plane operations on a subscription: a storage account created,
a role assigned, a network rule changed. It is on, it costs nothing, and it keeps 90 days. Reading a
blob is a *data-plane* operation and does not appear there; it is in the storage account's resource
logs, which exist only once somebody adds a diagnostic setting that sends them somewhere.

**Sign-ins are a separate log, in Microsoft Entra ID**, because identity lives there and not in the
subscription. How long Entra keeps sign-in and audit logs depends on the licence, from days to a
month, so an investigation that starts late finds nothing unless they were exported.

## Google Cloud

Cloud Audit Logs has four kinds, and two defaults matter:

- **Admin Activity** logs record configuration changes. They are always written, they cannot be
  switched off, and they are kept for 400 days at no charge;
- **Data Access** logs record reads of configuration and reads and writes of user data. They are
  **off by default**, except for BigQuery, because they can be enormous, and they are billed when
  switched on;
- **System Event** logs record what Google's own systems did to your resources;
- **Policy Denied** logs record calls refused by a security policy, such as a VPC Service Controls
  perimeter.

## What carries across

Three habits are the same at every provider, whatever the product is called:

1. **Decide the data events before you need them.** The default answers who changed a setting. Who
   read the patients' files is off everywhere, and nobody can switch it on retroactively.
2. **Send the records out of the account they describe.** A log-archive account, a separate project,
   a separate subscription: somewhere the administrators being recorded cannot delete.
3. **Read the times in UTC.** All three write timestamps in UTC, and a timeline in local time is
   built after the records are read, never instead.
