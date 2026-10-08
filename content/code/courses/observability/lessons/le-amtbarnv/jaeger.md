---
title: Finding traces in Jaeger
version: 2
---

Reading a trace needs its id, and so far the id came from a log line. The other way in is a
**search**: every trace store indexes spans by service, operation, duration, time and attributes,
so you can ask for the traces that look like the problem.

Jaeger's search form at `localhost:16686` takes those fields, and its documented HTTP API, version
3, takes the same ones. Every checkout of the last three minutes that took at least 400 ms, with the two ends of those three
minutes written the way the API takes them:

```sh
START=$(date -u -d '-3 min' +%Y-%m-%dT%H:%M:%SZ) END=$(date -u +%Y-%m-%dT%H:%M:%SZ)
```

`$START` and `$END` go where the transcript has two times:

```
ana@obs:~/shop$ curl -sG localhost:16686/api/v3/traces --data-urlencode query.service_name=storefront --data-urlencode 'query.operation_name=POST /checkout' --data-urlencode query.duration_min=400ms --data-urlencode query.start_time_min=2026-10-02T16:36:11Z --data-urlencode query.start_time_max=2026-10-02T16:39:11Z --data-urlencode query.search_depth=5 | jq -r '[.result.resourceSpans[].scopeSpans[].spans[] | select(.name == "POST /checkout")] | .[] | [.traceId, ((((.endTimeUnixNano | tonumber) - (.startTimeUnixNano | tonumber)) / 1e6) | floor)] | @tsv'
5c2c908e9788a59688745c45c443f1c1	431
c3490bff2db63cee980be1857e2a7435	428
524e5284c6ecc3306a24cf03feb82850	434
3aa2e4729024e38908cb92da13a2a0f6	432
ced73eb37b6c3b1ec4a1e9332fd9990d	422
```

Five traces, the most the request asked for, each with the root span's duration in milliseconds. In
the interface the same search draws them as dots on a time axis, with duration as the height. The
dots worth opening are the high ones and the ones that sit apart from the crowd.

Three things about searching are worth knowing before an incident rather than during one:

- **A search sees only what was kept.** Lesson 12 samples traces, and a search over a sample finds
  the slow requests that happened to be sampled. Whether those are representative is that lesson's
  subject.
- **The attributes you can search are the attributes somebody wrote.** A search for the checkouts of
  one product works only because the storefront put `shop.sku` on its span in lesson 2. If nobody
  set it, no form can find it.
- **The store decides how long it lasts.** The lab's Jaeger keeps traces in memory and forgets them
  on restart. In production it writes to Elasticsearch, OpenSearch or Cassandra, with a retention
  chosen exactly as lesson 10 chose one for logs.

The lab reads one trace with `/api/traces/<id>`, the endpoint the interface itself uses. It has
stayed stable for years, but the project documents version 3 as the API to build on, and a script
that outlives an upgrade should use that one.

Jaeger began at Uber in 2015 and is now a CNCF project. Version 2 is built on the OpenTelemetry
Collector, which is why the lab's Collector speaks to it in OTLP, the same protocol the services
speak to the Collector.