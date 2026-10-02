---
title: Variables: one dashboard for every service
version: 1
---

The dashboard's queries say `$job` where a service name would go, and a **variable** at the top of
the dashboard chooses what `$job` means. Its values are not written in the file; they are asked of
Prometheus, with `label_values(http_server_requests_total, job)`, every time the dashboard loads.
Grafana turns that into a request for the label's values, which can be sent by hand through the
data source:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" localhost:3000/api/datasources/uid/prometheus/resources/api/v1/label/job/values | jq -c .data
["blackbox","mailer","node","orders","otel-collector","payments","postgres","pushgateway","rabbitmq","storefront"]
```

The list includes every job, and the variable offers the ones that actually have the request
counter: storefront, orders, payments. **One dashboard then serves every service that publishes the
same metrics**, and a service added next month appears in the list without anybody editing the
file. That is the strongest argument for the consistent naming of lessons 5 and 6: a dashboard
written once for `http_server_requests_total` works for every service that uses the name, and for
none that invented its own.

Variables have one cost that is easy to miss: a variable whose query is expensive runs on every page
load, for every viewer. `label_values` on one metric is cheap; a variable built from a heavy query
over thirty days is a slow dashboard before a single panel has drawn.
