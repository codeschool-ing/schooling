---
title: A week of the shop's requests
version: 1
---

**The data in this course is generated, by a query, and it says so.** No real shop's logs are in it. One
command builds a week of requests in the shape of Application Insights' `AppRequests` table, the table
lesson 11 explains, and every lesson that needs it loads it the same way. Save it as `requests.kql` beside
`kql.py`:

```kql
// requests.kql: one week of the shop's requests, in the shape of Application Insights' AppRequests table
.set-or-replace AppRequests <|
range i from 0 to 302399 step 1
| extend TimeGenerated = datetime(2026-10-12 03:00) + i * 2s
| extend hour = hourofday(TimeGenerated - 3h)
| where abs(hash(i, 1000)) < iff(hour between (1 .. 6), 300, 1000)
| extend h = abs(hash(i * 3, 1000))
| extend Name = case(h < 500, "GET /products", h < 750, "GET /cart", h < 880, "POST /cart", "POST /checkout")
| extend broken = Name == "POST /checkout" and TimeGenerated between (datetime(2026-10-15 17:05) .. datetime(2026-10-15 17:47))
| extend ResultCode = case(broken and h % 3 != 0, "500", abs(hash(i * 5, 1000)) == 0, "500", "200")
| extend DurationMs = round(35.0 + abs(hash(i * 7, 120)) + iff(abs(hash(i * 11, 100)) == 0, 900.0, 0.0) + iff(broken, 3000.0, 0.0), 1)
| project TimeGenerated, OperationId = strcat("op-", tostring(i)), Name, ResultCode, Success = ResultCode == "200",
    DurationMs, AppRoleName = "shop-api", ItemCount = 1
```

It reads in one pass, top to bottom, which is how all KQL reads. `range` makes one row per two seconds
from midnight in São Paulo on Monday 12 October 2026, which is 03:00 in UTC, the time zone every workspace
stores. `hash()` gives each row a fixed pseudo-random number, so the week is the same on your computer as
on the one this course was recorded on. Between 01:00 and 07:00 local time seven rows in ten are dropped,
because a shop is quieter at night. Each request gets a route, a result and a duration, and on Thursday,
from 14:05 to 14:47 local time, two in three checkouts fail and take three seconds longer. **That window is
the incident** lessons 10, 11, 14 and 15 investigate; for now it is just rows.

`.set-or-replace` runs the query and stores its result as the table, replacing any table of that name, so
loading twice is harmless:

```
ana@laptop:~/azure/kusto$ python3 kql.py < requests.kql
ExtentId                              OriginalSize  ExtentSize  CompressedSize  IndexSize  RowCount
3b700688-db65-47e5-8021-6a4c8850c5f7  21074527.0    2562450.0   1719652.0       842798.0   249717
```

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | count'
Count
249717
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | take 3'
TimeGenerated         OperationId  Name           ResultCode  Success  DurationMs  AppRoleName  ItemCount
2026-10-12T03:00:00Z  op-0         GET /cart      200         True     94.0        shop-api     1
2026-10-12T03:00:02Z  op-1         GET /products  200         True     112.0       shop-api     1
2026-10-12T03:00:04Z  op-2         GET /products  200         True     93.0        shop-api     1
```

249,717 rows. The command's answer is the first thing worth reading: **`OriginalSize` is the size of the
data as it arrived, about 21 MB**, and `ExtentSize`, about 2.6 MB, is what the engine actually keeps after
compressing and indexing it. Ingestion is billed on the first number, not the second. The next section
turns that into money.
