---
title: The timeline, built from what the systems recorded
version: 1
---

**A timeline built from memory is a story; one built from records is evidence.** Three sources cover
Thursday. The requests are lesson 9's. The other two are written here, by the course, and say so.

The **activity log** records every change made through Resource Manager, in a table called
`AzureActivity`: what operation, by whom, from where, and whether it succeeded. Eleven of the week's
changes, in its shape (lesson 21 reads this table properly):

```kql
// activity.kql: the subscription's week of changes, in the shape of the AzureActivity table
.set-or-replace AzureActivity <|
datatable(TimeGenerated: datetime, OperationNameValue: string, ActivityStatusValue: string, Caller: string,
          CallerIpAddress: string, ResourceGroup: string, Resource: string, Properties: dynamic) [
    datetime(2026-10-12 13:14), "MICROSOFT.RESOURCES/DEPLOYMENTS/WRITE", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "shop-main-41", dynamic({}),
    datetime(2026-10-12 13:21), "MICROSOFT.WEB/SITES/SLOTS/SLOTSSWAP/ACTION", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "app-shop-api/staging", dynamic({}),
    datetime(2026-10-13 18:40), "MICROSOFT.AUTHORIZATION/ROLEASSIGNMENTS/WRITE", "Success", "ana@example.com", "203.0.113.24", "rg-shop", "rg-shop", dynamic({"role": "Monitoring Reader", "principal": "carla@example.com"}),
    datetime(2026-10-14 12:05), "MICROSOFT.RESOURCES/DEPLOYMENTS/WRITE", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "shop-main-42", dynamic({}),
    datetime(2026-10-14 12:11), "MICROSOFT.WEB/SITES/SLOTS/SLOTSSWAP/ACTION", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "app-shop-api/staging", dynamic({}),
    datetime(2026-10-15 16:58), "MICROSOFT.SQL/SERVERS/DATABASES/WRITE", "Failure", "bruno@example.com", "198.51.100.7", "rg-shop", "sql-shop/shop", dynamic({"sku": "S1", "error": "AuthorizationFailed"}),
    datetime(2026-10-15 17:02), "MICROSOFT.SQL/SERVERS/DATABASES/WRITE", "Success", "bruno@example.com", "198.51.100.7", "rg-shop", "sql-shop/shop", dynamic({"sku": "S1", "previousSku": "S3"}),
    datetime(2026-10-15 17:44), "MICROSOFT.SQL/SERVERS/DATABASES/WRITE", "Success", "carla@example.com", "203.0.113.51", "rg-shop", "sql-shop/shop", dynamic({"sku": "S3", "previousSku": "S1"}),
    datetime(2026-10-16 14:30), "MICROSOFT.INSIGHTS/SCHEDULEDQUERYRULES/WRITE", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "checkout-failing", dynamic({}),
    datetime(2026-10-17 21:12), "MICROSOFT.STORAGE/STORAGEACCOUNTS/DELETE", "Success", "ana@example.com", "203.0.113.24", "rg-test-ana", "sttestana01", dynamic({}),
    datetime(2026-10-18 10:03), "MICROSOFT.KEYVAULT/VAULTS/WRITE", "Success", "3fa2c1d0-7b8e-4c55-9a1e-2d4b6f8e0c11", "", "rg-shop", "kv-shop-prod", dynamic({})
]
```

The **incident channel**, as a table: what people did and when, written down as they did it:

```kql
// incident-log.kql: what people did during Thursday's incident, as the incident channel recorded it
.set-or-replace IncidentLog <|
datatable(TimeGenerated: datetime, Who: string, What: string) [
    datetime(2026-10-15 17:15), "pager", "checkout burn-rate alert pages carla (on call)",
    datetime(2026-10-15 17:18), "carla@example.com", "acknowledged; checkout failing, SQL timeouts in AppDependencies",
    datetime(2026-10-15 17:22), "carla@example.com", "declared SEV2, carla incident commander, dani communications",
    datetime(2026-10-15 17:29), "dani@example.com", "status page: checkout failing for some customers, investigating",
    datetime(2026-10-15 17:38), "carla@example.com", "activity log: sql-shop/shop scaled S3 to S1 at 17:02 by bruno",
    datetime(2026-10-15 17:44), "carla@example.com", "scaled sql-shop/shop back to S3",
    datetime(2026-10-15 17:52), "carla@example.com", "checkout healthy for 5 minutes; mitigated",
    datetime(2026-10-15 18:05), "dani@example.com", "status page: resolved, postmortem to follow"
]
```

Save both beside the others and load them with `python3 kql.py < activity.kql` and
`python3 kql.py < incident-log.kql`. Then put all three on one clock, in São Paulo time, because that is
the time the people involved remember:

```kql
// timeline.kql: three sources, one clock, in São Paulo time
let since = datetime(2026-10-15 16:30);
let until = datetime(2026-10-15 18:30);
union
    (AzureActivity | where TimeGenerated between (since .. until)
        | project TimeGenerated, Source = "activity", Event = strcat(Caller, " ", OperationNameValue, " ", ActivityStatusValue, " ", tostring(Properties.sku))),
    (AppRequests | where Name == "POST /checkout" and TimeGenerated between (since .. until)
        | summarize failed = countif(not(Success)) by TimeGenerated = bin(TimeGenerated, 10m)
        | where failed > 0
        | project TimeGenerated, Source = "requests", Event = strcat(failed, " checkouts failed in 10 minutes")),
    (IncidentLog | project TimeGenerated, Source = "channel", Event = strcat(Who, ": ", What))
| project Local = format_datetime(datetime_utc_to_local(TimeGenerated, "America/Sao_Paulo"), "HH:mm"), Source, Event
| order by Local asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < timeline.kql
Local  Source    Event
13:58  activity  bruno@example.com MICROSOFT.SQL/SERVERS/DATABASES/WRITE Failure S1
14:00  requests  9 checkouts failed in 10 minutes
14:02  activity  bruno@example.com MICROSOFT.SQL/SERVERS/DATABASES/WRITE Success S1
14:10  requests  32 checkouts failed in 10 minutes
14:15  channel   pager: checkout burn-rate alert pages carla (on call)
14:18  channel   carla@example.com: acknowledged; checkout failing, SQL timeouts in AppDependencies
14:20  requests  20 checkouts failed in 10 minutes
14:22  channel   carla@example.com: declared SEV2, carla incident commander, dani communications
14:29  channel   dani@example.com: status page: checkout failing for some customers, investigating
14:30  requests  28 checkouts failed in 10 minutes
14:38  channel   carla@example.com: activity log: sql-shop/shop scaled S3 to S1 at 17:02 by bruno
14:40  requests  14 checkouts failed in 10 minutes
14:44  channel   carla@example.com: scaled sql-shop/shop back to S3
14:44  activity  carla@example.com MICROSOFT.SQL/SERVERS/DATABASES/WRITE Success S3
14:52  channel   carla@example.com: checkout healthy for 5 minutes; mitigated
15:05  channel   dani@example.com: status page: resolved, postmortem to follow
```

Read it top to bottom and the incident tells itself. A `requests` row is labelled with the start of its
ten-minute bin, so the 14:00 row holds the failures from 14:05 on. At 13:58 `bruno` tried to change the database's
size and was refused; at 14:02 he succeeded, **S1**, down from S3. Three minutes later checkouts started
failing. The page came at 14:15, the declaration at 14:22. At 14:38 Carla found the change in the activity
log, at 14:44 she reverted it, and the failures stopped inside that ten-minute bin. Carla's note says 17:02 because she copied it from
the log, in UTC, which is how two clocks get into one channel; a timeline in one time zone settles it.

**The cause was in the activity log the whole time.** Twenty-three minutes passed between the page and
looking there, and that is the finding that matters most: the first question in any incident is *what
changed?*, and the activity log is where Azure answers it. The shop's runbook now starts with this query.
