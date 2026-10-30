---
title: Requests, dependencies, and the id that joins them
version: 1
---

**Application Insights is the part of Azure Monitor that watches an application from inside it.** An
SDK or an OpenTelemetry distribution in the application, lesson 13's subject, records what the code does
and sends it to an Application Insights resource, which stores it in a Log Analytics workspace, in tables
of its own:

| table | one row for |
|---|---|
| `AppRequests` | each request the application served |
| `AppDependencies` | each call it made while serving one: SQL, HTTP, a queue, a cache |
| `AppExceptions` | each exception it recorded |
| `AppTraces` | each log line the application wrote |
| `AppMetrics`, `AppPerformanceCounters` | numbers the SDK collected |

What makes these more than five lists is **`OperationId`**: every row produced while serving one request
carries the same value, so a request and everything it did can be put back together. (In the classic
Application Insights query view the same field is called `operation_Id`; the workspace tables spell it
`OperationId`.)

Lesson 9 loaded `AppRequests`. This lesson adds `AppDependencies`, generated from it the same way and
saying so: every write request makes one SQL call, every checkout also calls the payment provider. The checkouts of Thursday's incident made SQL calls that took three seconds and failed with `-2`, the code .NET's SQL client reports for a timeout. Save it as `dependencies.kql` beside the other files:

```kql
// dependencies.kql: the calls each write request made, in the shape of AppDependencies
.set-or-replace AppDependencies <|
AppRequests
| where Name in ("POST /cart", "POST /checkout")
| extend slow = DurationMs > 2000
| project TimeGenerated, OperationId, Name = iff(Name == "POST /cart", "INSERT basket_items", "INSERT orders"),
    Target = "sql-shop.database.windows.net | shop", DependencyType = "SQL",
    ResultCode = iff(slow and not(Success), "-2", "0"), Success = not(slow and not(Success)),
    DurationMs = iff(slow, iff(Success, 2900.0, 3000.0), round(DurationMs * 0.4, 1)), AppRoleName, ItemCount
| union (
    AppRequests
    | where Name == "POST /checkout" and not(DurationMs > 2000 and not(Success))
    | project TimeGenerated, OperationId, Name = "POST /v1/charges", Target = "api.payments.example",
        DependencyType = "HTTP", ResultCode = "201", Success = true, DurationMs = round(DurationMs * 0.3, 1),
        AppRoleName, ItemCount)
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < dependencies.kql | cut -c1-80
ExtentId                              OriginalSize  ExtentSize  CompressedSize  
b7ff82e8-7784-49f0-a4de-b31f92a1ba02  11208972.0    1442364.0   1045705.0       
ana@laptop:~/azure/kusto$ python3 kql.py 'AppDependencies | summarize calls = count(), failed = countif(not(Success)) by DependencyType, Target'
DependencyType  Target                                calls  failed
HTTP            api.payments.example                  29760  0
SQL             sql-shop.database.windows.net | shop  62446  103
```

The answer is cut to 80 columns here; the table it creates has some 62,000 SQL calls and 30,000 calls to
the payment provider, and the 103 failures are all SQL. Like `AppRequests`, the real table has many more
columns, `Data` with the SQL text among them, and the course keeps the ones it uses.
