---
title: What a workspace is, and how many to have
version: 1
---

**A Log Analytics workspace is a Kusto database that Azure Monitor manages for you**: the tables are
created by the services that write to them, every row gets a `TimeGenerated` and a `_ResourceId`, and the
workspace has a region, a retention and a bill. Diagnostic settings, data collection rules and Application
Insights all write into one, and every query you write in this course would run in one unchanged, against
real tables of the same names.

**How many workspaces** is the first design question, and Microsoft's own guidance is to start with as
few as possible. One workspace per environment is the usual shape: `log-shop-prod` and `log-shop-dev`,
because production data has different readers and a different retention. Reasons to add more are
specific: data that must stay in a particular region, a team that is billed separately, an operator
outside the company who may read some of it and nothing else.

What makes one workspace workable for several teams is **resource-context access**: a person with read
access to `rg-shop` can query the rows that came from `rg-shop`'s resources, in the shared workspace, and
no others. The workspace setting for it is *access control mode*, and the permission comes from the
resources rather than from the workspace.

## Table plans

Every table in a workspace has a **plan**, and the plan sets what the table can do and what it costs.

| plan | what it is for | what it gives up |
|---|---|---|
| **Analytics** | the default: anything you alert on, chart or query often | nothing; it is the most expensive per GB |
| **Basic** | high-volume logs you query occasionally, while troubleshooting | some query features; each query is billed by the data it scans |
| **Auxiliary** | verbose logs kept for audit or rare investigation | most query speed and features; cheapest to ingest |

The shop keeps `AppRequests` and its other application tables on Analytics, because lessons 12 and 14
alert on them. A container's chatty console output, read only when somebody is debugging, is the
candidate for Basic. None of this exists in the emulator, which has one kind of table; the plans are from
Microsoft's documentation.
