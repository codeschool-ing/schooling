---
title: let, join and parse
version: 1
---

**`let` names something for the rest of the query, and `join` brings two tables together on a column
they share.** The shop's routes belong to teams, and that mapping is not in the logs. A small table
written inline with `datatable` supplies it:

```kql
// owners.kql: which team answers for each route's failures this week
let owners = datatable(Name: string, Team: string) [
    "GET /products", "catalogue",
    "GET /cart", "basket",
    "POST /cart", "basket",
    "POST /checkout", "payments"
];
AppRequests
| where not(Success)
| summarize failed = count() by Name
| join kind=leftouter owners on Name
| project Team, Name, failed
| order by failed desc
```

```

```

`kind=leftouter` keeps every route from the left side even if the right has no owner for it, which is
the kind to reach for when the right side is a lookup: a route somebody forgot to add would then show an
empty team rather than disappear from the answer. The default join kind in KQL is not the inner join
most people expect; it removes duplicate keys from the left side first. **Say the kind every time.**

Over the whole week, catalogue has the most failures, 135, and payments 130. That is the number a weekly
report would show, and it says catalogue had the worse week. The previous section says otherwise: almost
all of payments' failures fell in one 42-minute window, while catalogue's were spread thin across seven
days. **A total answers "how many", never "how bad".**

## parse

`parse` cuts a string into columns by a pattern, which is how a field written as text becomes something to
group by. The route names hold a method and a path:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'AppRequests | parse Name with Method " " Path | summarize requests = count() by Method'
Method  requests
GET     187271
POST    62446
```

The pattern reads as the string looks: whatever comes before a space goes into `Method`, the rest into
`Path`. Three requests in four were reads. In real logs, `parse` is what turns a message such as
`order 1042 failed after 3 retries` into an order number and a count, and `parse_json()` does the same
for a field that holds JSON.
