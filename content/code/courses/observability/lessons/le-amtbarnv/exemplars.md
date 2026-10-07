---
title: Exemplars, from a metric to a trace
version: 2
---

Lesson 1 left one join for this lesson. A latency histogram says that some checkouts took between
0.25 and 0.5 seconds, and nothing about which. **An exemplar is the id of one real request, kept
beside a bucket's count**, so a point on a graph can be opened as a trace.

Three pieces have to agree for one to reach a screen. The first is in the code that observes the
duration, the shop's shared `web.py`:

```schooling-example
{
  "language": "python",
  "file": "common/web.py",
  "parts": [
    {
      "code": "    @app.after_request\n    def finish(response):\n        route = request.url_rule.rule if request.url_rule else \"unmatched\"\n        if route != \"/metrics\":\n            REQUESTS.labels(route, request.method, str(response.status_code)).inc()\n"
    },
    {
      "code": "            ctx = trace.get_current_span().get_span_context()\n            exemplar = {\"trace_id\": format(ctx.trace_id, \"032x\")} if ctx.is_valid else None\n            DURATION.labels(route, request.method).observe(time.perf_counter() - g.started, exemplar)\n",
      "note": "**The current span's trace id becomes the exemplar**, but only when there is a valid span. Outside a trace there is nothing to point at, and the observation is made without one."
    },
    {
      "code": "        return response\n\n    @app.get(\"/metrics\")\n    def metrics():\n        # OpenMetrics, which carries exemplars, for a scraper that asks for it\n        encoder, content_type = choose_encoder(request.headers.get(\"Accept\"))\n        return Response(encoder(REGISTRY), content_type=content_type)\n",
      "note": "`choose_encoder` reads the scraper's `Accept` header and answers OpenMetrics to a scraper that asks for it, the classic text format to anybody else. Only OpenMetrics carries exemplars."
    }
  ]
}
```

The second is Prometheus, which drops exemplars unless a feature flag tells it to store them. That is the
override saved at the start of this lesson:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  prometheus:
    command: [--config.file=/etc/prometheus/prometheus.yml, --web.enable-lifecycle,
              --storage.tsdb.path=/prometheus, --enable-feature=exemplar-storage]
```

The third is the format on the wire. The text format lesson 5 read cannot carry an exemplar;
**OpenMetrics can**, and Prometheus asks for it when it scrapes. Asking for it by hand, from inside the
lab's network, shows what the scrape receives from `orders`:

```
ana@obs:~/shop$ docker compose exec prometheus wget -qO- --header 'Accept: application/openmetrics-text' orders:8081/metrics | grep -m2 'duration_seconds_bucket{.* # '
http_server_request_duration_seconds_bucket{le="0.5",method="POST",route="/orders"} 1071.0 # {trace_id="ae16afa43924732d71156920f9e3b5d1"} 0.42349258400008694 1790959284.789409
```

After the `#` sits one trace id with the value it measured and when. A bucket keeps the last
exemplar observed in it, so each bucket points at a recent request in its own range. Prometheus
collects them on every scrape and answers for them by query:

```
ana@obs:~/shop$ curl -sG localhost:9090/api/v1/query_exemplars --data-urlencode 'query=http_server_request_duration_seconds_bucket{job="orders",route="/orders"}' --data-urlencode start=$(date -d '-2 min' +%s) --data-urlencode end=$(date +%s) | jq -r '.data[].exemplars[:3][] | [.labels.trace_id, .value] | @tsv'
f9c0ac383b95bb01439b49c86b90a087	0.42279977799989865
9198ac701d96e56d0fa89f8a3ff26156	0.42294279299949267
687836b422656ee663235dcf6f7e81fb	0.4306990329996552
```

And one of those ids, opened in Jaeger, is the trace of that request:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/f9c0ac383b95bb01439b49c86b90a087 | jq -r -f selftime.jq | head -3
storefront	POST /checkout	426 ms	self 3 ms
orders	POST /orders	423 ms	self 16 ms
orders	INSERT	2 ms	self 2 ms
```

In Grafana the same exemplars are drawn as dots over the histogram's panel. The datasource from
lesson 7 needs one more setting, `exemplarTraceIdDestinations`, naming the Jaeger datasource, and a
click on a dot opens the trace. **The slow bucket's dot is a slow request**, which is what nobody
could get from a graph before.

The storefront has no exemplars, and the reason is worth knowing. Its `POST /checkout` span is
written by hand, and it has ended by the time `after_request` measures the duration, so there is
no current span to name. **An exemplar can only point at a span that is still open when the
measurement is taken**. Automatic instrumentation in `orders` keeps Flask's span open around the
whole request, which is why `orders` has them.

Before the next lesson, take the fault and the override away:

```sh
rm faults/payments.json compose.override.yaml
docker compose up -d prometheus
```
