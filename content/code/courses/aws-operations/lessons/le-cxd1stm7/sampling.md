---
title: Sampling, and how many traces are worth keeping
version: 1
---

Tracing every request of a busy service costs money, network and a little latency, and most of those
traces would show the same thing. **X-Ray samples**: it records a fixed number of requests per second,
the **reservoir**, and a percentage of the rest, the **rate**. The default rule, as AWS documents it, is
a reservoir of one request per second and a rate of 5%.

At 200 requests per second, the default records 1 + 5% of the other 199, about 10.95 traces a second:
roughly 946,000 a day, 28.4 million in a 30-day month. **The reservoir guarantees the quiet services
get traced at all**; the rate keeps a busy service's volume in proportion.

```
ana@laptop:~/aws/traces$ python3 price.py AWSXRay TracesStored
AWSXRay, sa-east-1, published 2026-09-11
  Global-XRay-TracesStored                 0.000000 USD per Traces     AWS X-Ray - Traces Stored Free Tier - 100,000 traces
  SAE1-XRay-InsightsTracesStored           0.000001 USD per Traces     AWS X-Ray - Total Insights Traces Processed - South America (Sao Paulo)
  SAE1-XRay-TracesStored                   0.000005 USD per traces     AWS X-Ray - Total Traces Stored - South America (Sao Paulo)
```

Five dollars per million traces stored, after a free 100,000 a month (the `Global` line). At 28.4 million
a month the shop pays about 141 USD for one busy service, at the default rate. A rule for the health
check at 0% and one for checkout at 10% spends the budget where questions are asked.

## Rules, and where they live

Sampling rules are kept in X-Ray, not in each service: the SDKs and collectors fetch them, so a rule
changed in X-Ray changes what every service records within a minute, with no deployment. A rule
matches requests by service name, HTTP method, URL path and host, and has a priority, a reservoir and a
rate. The shop would keep the health check out and record more of the expensive path:

| priority | match | reservoir | rate |
|---|---|---|---|
| 10 | `GET /health` | 0 | 0% |
| 20 | `POST /checkout` | 2 | 10% |
| 10000 | everything else (the default) | 1 | 5% |

```
ana@laptop:~/aws/traces$ aws xray get-sampling-rules 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (404) when calling the GetSamplingRules operation: <!doctype html>
```

moto does not implement sampling rules: the call is not found. The table is X-Ray's documented model,
and nothing in it was run.

## The decision travels too

A request is sampled or not **once, at the first service**, and the decision rides in the header's
`Sampled=` field to every service after it. If each service decided for itself, a trace would come back
with holes: the API recorded, the payments service not. Keeping the first decision is what makes a
recorded trace complete. The consequence for rare errors: **at 5%, nineteen of twenty failed checkouts
leave no trace**, so errors are found by metrics and logs first, and the trace is there for the ones
that were sampled.
