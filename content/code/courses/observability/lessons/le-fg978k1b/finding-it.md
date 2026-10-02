---
title: Finding the label that did it
version: 1
---

In the experiment the culprit was known. In production it is not: memory climbs, scrapes slow down,
and somewhere among hundreds of metrics one has started to multiply. **Prometheus keeps statistics
about its own head block**, and its status API answers the two questions that find it, which
metrics have the most series and which labels have the most values:

```
ana@obs:~/shop$ curl -s localhost:9090/api/v1/status/tsdb | jq -r '.data.seriesCountByMetricName[:3][] | [.name, .value] | @tsv'
demo_logins_total	20003
demo_logins_created	20003
erlang_vm_allocators	496
ana@obs:~/shop$ curl -s localhost:9090/api/v1/status/tsdb | jq -r '.data.labelValueCountByLabelName[:3][] | [.name, .value] | @tsv'
user_id	20000
__name__	1225
le	113
```

`demo_logins_total` and `demo_logins_created` with about twenty thousand series each, far above
anything else; the next metric down, from RabbitMQ, has 496. And the label with the most distinct
values is `user_id`, with 20000, against 1225 metric names in the whole lab. **Two requests and the
culprit has a name**: the metric, the label, and from the series' own labels, the job that sends it.

The same view exists in Prometheus's web interface under *Status*, *TSDB Status*. A habit worth
having is to look at it before trouble, so the normal numbers are known: in this lab, a few
thousand series and no label above a few hundred values. A team that knows its normal sees a jump
the day it happens; a team that does not, sees it the day Prometheus is killed for running out of
memory.
