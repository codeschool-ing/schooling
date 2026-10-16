---
title: Logs Insights, and the same questions answered with jq
version: 1
---

**CloudWatch Logs Insights** is a query language over log groups: it reads JSON fields by name,
filters, aggregates and sorts, and it is billed by the gigabyte of logs it scans. The question the
shop asks first during an incident is which paths are failing:

```
filter status >= 500
| stats count(*) as errors by path
| sort errors desc
```

Each line is a command applied to the result of the one before, joined by `|`. `filter` keeps
matching events; `stats` groups and counts; `sort` orders. Two more questions an incident asks, as
Insights queries:

```
filter path = "/checkout"
| stats pct(ms, 50) as p50, pct(ms, 99) as p99, count(*) as requests
```

```
filter status >= 500
| stats count(*) as errors by customer
| sort errors desc
| limit 3
```

## Against moto

```
ana@laptop:~/aws/logs$ QUERY=$(aws logs start-query --log-group-name /shop/api --start-time $(date -d '-1 hour' +%s) --end-time $(date +%s) --query-string 'filter status >= 500 | stats count(*) as errors by path' --query queryId --output text)
ana@laptop:~/aws/logs$ aws logs get-query-results --query-id $QUERY --query '[status, length(results), results[0][0]]'
[
    "Complete",
    300,
    {
        "field": "@ptr",
        "value": "299"
    }
]
```

`Complete`, and 300 results: moto returned every event, unfiltered and unaggregated, as a list of
pointers. **It does not evaluate Insights queries**, so none of the three above was run as written.
The questions themselves can still be answered: export the lines and ask `jq`, which reads JSON a
line at a time.

```
ana@laptop:~/aws/logs$ aws logs filter-log-events --log-group-name /shop/api --query 'events[].message' --output json | jq -r '.[]' > api.jsonl
ana@laptop:~/aws/logs$ wc -l api.jsonl
300 api.jsonl
```

Which paths fail, the first query:

```
ana@laptop:~/aws/logs$ jq -r 'select(.status >= 500) | .path' api.jsonl | sort | uniq -c | sort -rn
      3 /cart
      1 /checkout
```

How slow `/checkout` is, the second, computing the median and p99 the nearest-rank way of lesson 8:

```
ana@laptop:~/aws/logs$ jq -r 'select(.path == "/checkout") | .ms' api.jsonl | sort -n | awk '{ v[NR] = $1 } END { print "requests", NR, "p50", v[int(NR * 0.5)], "p99", v[int(NR * 0.99)] }'
requests 69 p50 51 p99 1390
```

And whether one customer is behind the errors, the third:

```
ana@laptop:~/aws/logs$ jq -r 'select(.status >= 500) | .customer' api.jsonl | sort | uniq -c | sort -rn | head -3
      1 c-1038
      1 c-1027
      1 c-1016
```

Four errors in 300 requests: three on `/cart`, one on `/checkout`, each from a different customer.
`/checkout` serves its median request in 51 ms and its p99 in 1,390. **No single customer is the
problem**, which rules out the explanation people reach for first. The numbers are small because the
sample is; the method is the one an incident uses.

## What Insights adds, and what it costs

`jq` over an export works for a few hundred lines on a laptop. Insights runs the same kind of question
over gigabytes, across several log groups, without moving them, and it finds fields in JSON lines by
itself. It is billed per gigabyte scanned, 0.009 USD in São Paulo by the price list, so a query over a
month of the shop's logs, 150 GB, costs 1.35 USD each time it runs. **Narrow the time range first**:
the range is what decides how much is scanned, not the filter.
