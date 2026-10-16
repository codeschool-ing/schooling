---
title: Custom metrics, and the dimension that multiplies the bill
version: 1
---

AWS publishes its services' own metrics, free: a load balancer's request count, a queue's depth, a
function's errors. **What the business cares about is not among them**: orders placed, payments
refused, the age of the oldest unshipped order. Those are **custom metrics**, published by the
application, and billed per metric per month:

```
ana@laptop:~/aws/metrics$ python3 price.py AmazonCloudWatch MetricMonitorUsage
AmazonCloudWatch, sa-east-1, published 2026-10-07
  Global-CW:MetricMonitorUsage             0.000000 USD per Metrics    Global
  SAE1-CW:MetricMonitorUsage               0.020000 USD per Metrics    $0.02 per metric-month for over 1,000,000 metrics - South America (Sao Paulo)
  SAE1-CW:MetricMonitorUsage               0.050000 USD per Metrics    $0.05 per metric-month for the next 750,000 metrics - South America (Sao Paulo)
  SAE1-CW:MetricMonitorUsage               0.100000 USD per Metrics    $0.10 per metric-month for the next 240,000 metrics - South America (Sao Paulo)
  SAE1-CW:MetricMonitorUsage               0.300000 USD per Metrics    $0.30 per metric-month for the first 10,000 metrics - South America (Sao Paulo)
ana@laptop:~/aws/metrics$ python3 price.py AmazonCloudWatch CW:Requests
AmazonCloudWatch, sa-east-1, published 2026-10-07
  Global-CW:Requests                       0.000000 USD per Requests   Global
  SAE1-CW:Requests                         0.000014 USD per Requests   $0.014 per 1,000 requests
```

Thirty cents a month for each of the first ten thousand metrics, less above that, and 1.4 cents per
thousand API requests on top. A metric exists for billing in any month in which a data point is
published to it, and **a metric is a distinct namespace, name and dimensions**, which is where the
cost hides.

## Cardinality

The shop wants latency per customer, to answer complaints. A dimension `Customer` with the customer's
id looks harmless and is the most expensive line in this lesson:

| dimensions | metrics |
|---|---|
| `Service` (3 services) | 3 |
| `Service`, `Stage` (2) | 6 |
| `Service`, `Stage`, `Endpoint` (40) | 240 |
| `Service`, `Stage`, `Endpoint`, `Customer` (20,000) | 4,800,000 |

Each row multiplies the one above. The last one, at the list prices above, is 10,000 metrics at 0.30,
240,000 at 0.10, 750,000 at 0.05 and the remaining 3,800,000 at 0.02, **some 140,500 USD a month** for
one latency metric. Per-customer questions belong in logs, which are billed by the gigabyte and queried
when somebody asks, which is lesson 9. **A dimension's values must be few and fixed**: services,
stages, endpoints, availability zones. Never ids, never anything a customer can create more of.

## Publishing without a call per data point

Calling `PutMetricData` for every request costs a request each and adds latency. Two better ways:

- **aggregate first**: collect a minute of values in the application and publish them in one call,
  with `--values` and `--counts` as the previous section did;
- **the Embedded Metric Format**: write a structured log line, and CloudWatch extracts the metric
  from it as the line arrives in a log group, with no API call at all.

An EMF line, as the shop's API would print it to standard output:

```json
{"_aws": {"Timestamp": 1792166400000, "CloudWatchMetrics": [{"Namespace": "Shop", "Dimensions": [["Service"]], "Metrics": [{"Name": "Latency", "Unit": "Milliseconds"}]}]}, "Service": "api", "Latency": 42, "customer": "c-48213", "path": "/cart"}
```

The `_aws` block declares that `Latency` is a metric with the dimension `Service`; everything else in
the line, the customer's id included, stays a log field, searchable and not a dimension. **One line is
both the metric and the detail behind it.** moto stores log lines and extracts nothing from them, so
the extraction was not run here.
