---
title: Asking through Grafana
version: 1
---

A panel's query is an HTTP request like any other, and it can be sent by hand. `query.json` asks for
the storefront's total request rate, in PromQL, addressed to the data source by its `uid`:

```
ana@obs:~/shop$ cat query.json
{
  "from": "now-5m",
  "to": "now",
  "queries": [
    {
      "refId": "A",
      "datasource": {"uid": "prometheus"},
      "expr": "sum(rate(http_server_requests_total{job=\"storefront\"}[1m]))",
      "instant": true
    }
  ]
}
```

Sent to Grafana's query API, and then the same expression sent straight to Prometheus, a fraction of
a second later:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .grafana-password) -H 'Content-Type: application/json' -d @query.json localhost:3000/api/ds/query | jq -c '.results.A.frames[0].data.values'
[[1790936947924],[5.084097777777777]]
ana@obs:~/shop$ curl -sG localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_server_requests_total{job="storefront"}[1m]))' | jq -c '.data.result[0].value'
[1790936948.040,"5.0846133333333325"]
```

**The same number, 5.08 requests a second**, with a timestamp in milliseconds from Grafana and in
seconds from Prometheus. Grafana translated the request, passed it on, and reshaped the answer into
its own format of *frames*, columns of values that every panel type knows how to draw. Nothing was
computed in Grafana.

That has two consequences worth knowing before building anything on it. A slow dashboard is almost
always **a slow query in the data source**, and the fix is in PromQL or LogQL, a recording rule or a
narrower time range, not in Grafana. And a dashboard opened by fifty people at once, refreshing every
thirty seconds, is fifty times every panel's query against Prometheus, which is the cheapest reason
there is to give a heavy panel a recording rule.
