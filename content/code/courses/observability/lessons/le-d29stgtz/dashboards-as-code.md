---
title: A dashboard is a file
version: 1
---

Dashboards built by clicking have a familiar life: somebody makes a good one, somebody else changes
a query to investigate something and forgets to change it back, and a month later nobody knows which
version was right or who broke it. **A dashboard stored as a file in version control has a history,
a review, and a way back.** Grafana's dashboards are JSON, and the lab's provisioning reads every
file in `grafana/dashboards` on start-up and again every few seconds. The shop's:

```schooling-example
{
  "language": "json",
  "file": "grafana/dashboards/shop.json",
  "parts": [
    {
      "code": "{\n  \"uid\": \"shop\",\n  \"title\": \"Shop: requests, errors, duration\",\n  \"tags\": [\"shop\"],\n  \"time\": {\"from\": \"now-30m\", \"to\": \"now\"},\n  \"refresh\": \"30s\",\n",
      "note": "**The dashboard's own `uid`, `shop`**, chosen in the file like the data sources' were, so links and annotations can name it on any Grafana that loads this file."
    },
    {
      "code": "  \"templating\": {\n    \"list\": [\n      {\n        \"name\": \"job\",\n        \"type\": \"query\",\n        \"datasource\": {\"uid\": \"prometheus\"},\n        \"query\": \"label_values(http_server_requests_total, job)\",\n        \"current\": {\"text\": \"storefront\", \"value\": \"storefront\"}\n      }\n    ]\n  },\n",
      "note": "A **variable**, `job`, whose values come from a PromQL function. Every query below writes `$job` where a service name would go."
    },
    {
      "code": "  \"annotations\": {\n    \"list\": [\n      {\"name\": \"Deploys\", \"datasource\": {\"uid\": \"-- Grafana --\"}, \"enable\": true, \"iconColor\": \"orange\",\n       \"target\": {\"type\": \"tags\", \"tags\": [\"deploy\"]}}\n    ]\n  },\n",
      "note": "Annotations tagged `deploy` are drawn on every panel as vertical lines. The section on annotations creates two."
    },
    {
      "code": "  \"panels\": [\n    {\n      \"id\": 1, \"type\": \"timeseries\", \"title\": \"Requests per second, by status code\",\n      \"gridPos\": {\"x\": 0, \"y\": 0, \"w\": 12, \"h\": 8},\n      \"targets\": [{\"refId\": \"A\", \"datasource\": {\"uid\": \"prometheus\"},\n        \"expr\": \"sum by (code) (rate(http_server_requests_total{job=\\\"$job\\\"}[1m]))\", \"legendFormat\": \"{{code}}\"}]\n    },\n",
      "note": "A panel is a title, a position on a 24-column grid, and one or more queries addressed to a data source by `uid`. This one is the rate by status code, lesson 5's query."
    },
    {
      "code": "    {\n      \"id\": 2, \"type\": \"timeseries\", \"title\": \"Share of requests failing (5xx)\",\n      \"gridPos\": {\"x\": 12, \"y\": 0, \"w\": 12, \"h\": 8},\n      \"fieldConfig\": {\"defaults\": {\"unit\": \"percentunit\", \"min\": 0}},\n      \"targets\": [{\"refId\": \"A\", \"datasource\": {\"uid\": \"prometheus\"},\n        \"expr\": \"sum(rate(http_server_requests_total{job=\\\"$job\\\", code=~\\\"5..\\\"}[1m])) / sum(rate(http_server_requests_total{job=\\\"$job\\\"}[1m]))\"}]\n    },\n    {\n      \"id\": 3, \"type\": \"timeseries\", \"title\": \"Duration, 50th and 99th percentile\",\n      \"gridPos\": {\"x\": 0, \"y\": 8, \"w\": 24, \"h\": 8},\n      \"fieldConfig\": {\"defaults\": {\"unit\": \"s\", \"min\": 0}},\n      \"targets\": [\n        {\"refId\": \"A\", \"datasource\": {\"uid\": \"prometheus\"}, \"legendFormat\": \"p50\",\n         \"expr\": \"histogram_quantile(0.5, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\\\"$job\\\"}[1m])))\"},\n        {\"refId\": \"B\", \"datasource\": {\"uid\": \"prometheus\"}, \"legendFormat\": \"p99\",\n         \"expr\": \"histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\\\"$job\\\"}[1m])))\"}\n      ]\n    }\n  ]\n}\n",
      "note": "The error share, with its unit declared so the axis reads in per cent, and the two percentiles from lesson 6, each its own query in one panel."
    }
  ]
}
```

Grafana found it and filed it under the folder the provisioning file named:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" 'localhost:3000/api/search?query=Shop' | jq -c '.[] | {uid, title, folderTitle, tags}'
{"uid":"bg007clzi8vlsc","title":"Shop","folderTitle":null,"tags":[]}
{"uid":"shop","title":"Shop: requests, errors, duration","folderTitle":"Shop","tags":["shop"]}
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" localhost:3000/api/dashboards/uid/shop | jq -r '.meta.provisioned, (.dashboard.panels[] | .title)'
true
Requests per second, by status code
Share of requests failing (5xx)
Duration, 50th and 99th percentile
```

Two results for *Shop*: the folder, which Grafana created for the provisioning, and the dashboard,
with its `uid`, title and tag. The dashboard says it is **provisioned**, and that is not just a
label. An attempt to save over it through the API, the same request the interface's save button
sends:

```
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"dashboard": {"uid": "shop", "title": "edited by hand"}, "overwrite": true}' localhost:3000/api/dashboards/db
400
```

**Refused.** Grafana will not let a provisioned dashboard be overwritten in place, because the next
reading of the file would silently undo the edit. Somebody who wants to change it changes the file,
in a pull request, where a reviewer can see the query change before it reaches everybody's screen.
Anyone can still save a *copy* to experiment with, which is the right place for an experiment.
