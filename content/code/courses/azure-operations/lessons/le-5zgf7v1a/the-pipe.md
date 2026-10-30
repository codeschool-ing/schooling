---
title: A table in, a pipe of operators, an answer out
version: 1
---

**A KQL query starts with a table and passes it through operators, left to right, each separated by a
pipe, `|`.** Each operator receives a table and hands a table to the next one. There is no `SELECT …
FROM … WHERE` order to remember: you write the steps in the order they happen.

Every query in this lesson runs in the emulator from lesson 9, against the week in `AppRequests`. If the
emulator restarted since, recreate the database and load `requests.kql` again first; lesson 9 section 02
has both commands. Then, from `~/azure/kusto`:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | where Success == false | take 3'
TimeGenerated         OperationId  Name           ResultCode  Success  DurationMs  AppRoleName  ItemCount
2026-10-12T11:36:16Z  op-15488     GET /products  500         False    125.0       shop-api     1
2026-10-12T11:39:30Z  op-15585     GET /products  500         False    75.0        shop-api     1
2026-10-12T13:14:26Z  op-18433     GET /products  500         False    125.0       shop-api     1
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | where Sucess == false | take 3'
400 BadRequest: General_BadRequest: Request is invalid and cannot be executed.
Error details:
ClientRequestId='unspecified;72a22276-ec08-48ad-8a0e-afae39576c9d', ActivityId='f5b58c1e-33c9-4883-a470-4853bde9c1eb', Timestamp='2026-10-30T18:43:59.0190847Z'.
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | getschema | project ColumnName, ColumnType'
ColumnName     ColumnType
TimeGenerated  datetime
OperationId    string
Name           string
ResultCode     string
Success        bool
DurationMs     real
AppRoleName    string
ItemCount      long
```

The first query keeps the failed requests and **`take`s** three of them, any three: `take` promises no
order, which makes it the quickest way to see what a table looks like and the wrong way to answer anything.

The second has a typo, `Sucess`, and shows something about this lab worth knowing early: **the emulator
refuses the query and does not say why.** A Log Analytics workspace's query editor names the column it
cannot resolve and underlines it; the emulator answers `General_BadRequest` for every mistake. So when a
query is refused here, check the names first, and `getschema`, the third query, lists every column of a
table with its type. Strings are compared case-sensitively with `==` too: `Name == "post /checkout"`
matches nothing, and `=~` is the case-insensitive comparison.

## Filtering, and time

`where` keeps the rows for which a condition is true. Conditions combine with `and`, `or` and `not()`,
and time has its own conveniences: `between (start .. end)`, where the end can be a duration added to the
start.

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | where TimeGenerated between (datetime(2026-10-15 17:00) .. 1h) and Name == "POST /checkout" and not(Success) | top 4 by TimeGenerated asc | project TimeGenerated, ResultCode, DurationMs'
TimeGenerated         ResultCode  DurationMs
2026-10-15T17:05:12Z  500         3130.0
2026-10-15T17:05:44Z  500         3151.0
2026-10-15T17:06:00Z  500         3139.0
2026-10-15T17:06:24Z  500         3089.0
```

**`top 4 by TimeGenerated asc`** sorts and keeps the first four, which `take` would not have done, and
**`project`** keeps only the columns named, in that order. The answer is the first moment of the incident
lesson 9 planted: Thursday, 17:05:12, three seconds per failed checkout.

**Every timestamp in a workspace is UTC**, and 17:05 is not what anybody in São Paulo remembers. Convert
for the reader, never for the filter:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | where Name == "POST /checkout" and not(Success) and DurationMs > 2000 | summarize started = min(TimeGenerated), ended = max(TimeGenerated), failures = count() | extend started_local = datetime_utc_to_local(started, "America/Sao_Paulo")'
started               ended                 failures  started_local
2026-10-15T17:05:12Z  2026-10-15T17:46:28Z  103       2026-10-15T14:05:12Z
```

This query also previews the next section: `summarize` turned 103 failed slow checkouts into one row
with the first and last of them. 14:05 in São Paulo, to 14:46.
