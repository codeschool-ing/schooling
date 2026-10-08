---
title: Sending everything to one more place
version: 2
---

Trying a hosted product, or leaving one, used to mean touching every service. **With a Collector in
the middle it is one exporter more.** The services keep sending OTLP to the Collector, and the
Collector sends each trace to as many places as it has exporters.

The lab has no account with any vendor and should not, so the place is a stand-in: `standin.py`, a
twenty-line program in the sandbox that accepts OTLP over HTTP the way a hosted intake does and
prints who sent what:

`~/shop/scratch/standin.py`

```python
"""A stand-in for a hosted product's intake: it takes OTLP over HTTP, as JSON,
and prints who sent it and how much. It stores nothing."""
import gzip
import json
import logging

from flask import Flask, request

logging.getLogger("werkzeug").setLevel(logging.ERROR)
app = Flask(__name__)


@app.post("/v1/traces")
def traces():
    sent = request.get_data()
    body = gzip.decompress(sent) if request.headers.get("Content-Encoding") == "gzip" else sent
    data = json.loads(body)
    spans = sum(len(s["spans"]) for r in data["resourceSpans"] for s in r["scopeSpans"])
    services = sorted({a["value"]["stringValue"] for r in data["resourceSpans"]
                       for a in r["resource"]["attributes"] if a["key"] == "service.name"})
    print(f"api-key={request.headers.get('api-key')} spans={spans} bytes={len(sent)}"
          f" from={','.join(services)}", flush=True)
    return {}


app.run(host="0.0.0.0", port=4318)
```

The Collector's fourth configuration is the first one with one exporter more. Save it whole:

`~/shop/otel/collector-fanout.yaml`

```yaml
# The Collector of collector.yaml, sending every trace to one more place
# (lesson 13): an OTLP endpoint of the kind a hosted product gives you, with the
# key that identifies the account read from the environment.
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  fluent_forward:
    endpoint: 0.0.0.0:24224

processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 400
  batch: {}
  # A batch from Docker mixes every container's lines under one resource, so
  # the lines are regrouped by their own "service" field, one resource each,
  # before that field becomes the resource's service.name.
  groupbyattrs/service:
    keys: [service]
  transform/service:
    error_mode: ignore
    log_statements:
      - context: resource
        statements:
          - set(attributes["service.name"], attributes["service"]) where attributes["service"] != nil
  transform/logs:
    error_mode: ignore
    log_statements:
      - context: log
        conditions:
          - IsMatch(body, "^\\{")
        statements:
          - merge_maps(attributes, ParseJSON(body), "upsert")
          - set(severity_text, attributes["level"])
          - set(trace_id.string, attributes["trace_id"]) where attributes["trace_id"] != nil
          - set(span_id.string, attributes["span_id"]) where attributes["span_id"] != nil

exporters:
  debug:
    verbosity: basic
  otlp_grpc/jaeger:
    endpoint: jaeger:4317
    tls:
      insecure: true
  zipkin:
    endpoint: http://zipkin:9411/api/v2/spans
  otlp_http/loki:
    endpoint: http://loki:3100/otlp
  otlp_http/vendor:
    endpoint: http://vendor:4318
    encoding: json
    headers:
      api-key: ${env:VENDOR_API_KEY}

service:
  telemetry:
    metrics:
      readers:
        - pull:
            exporter:
              prometheus:
                host: 0.0.0.0
                port: 8888
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [otlp_grpc/jaeger, zipkin, otlp_http/vendor]
    logs:
      receivers: [fluent_forward]
      processors: [memory_limiter, transform/logs, groupbyattrs/service, transform/service, batch]
      exporters: [otlp_http/loki]
```

The exporter that points at the stand-in:

```
ana@obs:~/shop$ sed -n '/otlp_http\/vendor:/,/api-key/p' otel/collector-fanout.yaml
  otlp_http/vendor:
    endpoint: http://vendor:4318
    encoding: json
    headers:
      api-key: ${env:VENDOR_API_KEY}
```

Every hosted intake asks for the same three things: an endpoint, an encoding, and a key in a header.
The key's name differs by product, `api-key` for New Relic's OTLP endpoint and an `Authorization`
header for Dynatrace's, and the stand-in imitates the first. **The key is read from the environment,
never written in the file**, which keeps it out of the repository the file lives in:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  otel-collector:
    volumes: ["./otel/collector-fanout.yaml:/etc/otelcol/config.yaml:ro"]
    environment:
      VENDOR_API_KEY: lab-0000-not-a-real-key
ana@obs:~/shop$ docker compose run -d --rm --name vendor sandbox python standin.py 2>&1 | tail -1
5a6fe95e94eb75dfe46b636749a431b2284618806bd069c05d1c88e9742cc54c
```

The `cat` printed the override, saved as `~/shop/compose.override.yaml`. With it in place and the
stand-in running, recreate the Collector, and set the customers going for a quarter of an hour:

```sh
docker compose up -d otel-collector
docker compose run -d --rm loadgen python -m loadgen.load 5 900
sleep 30
```

Thirty seconds later, with customers buying, the stand-in's own output:

```
ana@obs:~/shop$ docker logs vendor 2>&1 | tail -4
api-key=lab-0000-not-a-real-key spans=42 bytes=2414 from=mailer
api-key=lab-0000-not-a-real-key spans=88 bytes=4846 from=orders
api-key=lab-0000-not-a-real-key spans=46 bytes=2937 from=payments,storefront
api-key=lab-0000-not-a-real-key spans=134 bytes=6736 from=mailer,orders
```

The same key on every request, and between 50 and 64 bytes a span once compressed: at the 35 spans a
second lesson 12 measured, about 170 MB a day. That is the number a hosted product's bill starts
from, measured here before anybody has quoted a price.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The services send OTLP once, to the Collector. The Collector sends every trace to three exporters at once: Jaeger, Zipkin and a hosted product's intake, which receives an api-key header read from the environment. Each exporter has its own queue, so when the hosted intake stops answering, its queue fills and its spans are dropped while Jaeger and Zipkin keep receiving.\"><defs><marker id=\"fo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">services</text><text x=\"85.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OTLP, once</text><rect x=\"220\" y=\"90\" width=\"150\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"295.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Collector</text><text x=\"295.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one pipeline</text><text x=\"295.0\" y=\"146.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">three exporters</text><rect x=\"460\" y=\"30\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Jaeger</text><rect x=\"460\" y=\"110\" width=\"230\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Zipkin</text><rect x=\"460\" y=\"190\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"575.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hosted intake</text><text x=\"575.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">api-key from the environment</text><path d=\"M152 130 L218 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fo-ah)\"></path><path d=\"M372 115 L458 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fo-ah)\"></path><path d=\"M372 130 L458 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fo-ah)\"></path><path d=\"M372 145 L458 212\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#fo-ah)\"></path><text x=\"400\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">own queue,</text><text x=\"400\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">fails alone</text></svg>", "caption": "Fan-out happens in one place, and each destination fails alone. Adding or removing a product is a change to this file, not to the services."}
```

**And when the vendor is down?** Each exporter has its own queue and its own retries, so one
destination failing should not touch the others. The stand-in is stopped and the Collector given a
minute:

```
ana@obs:~/shop$ docker stop vendor
vendor
ana@obs:~/shop$ ./promq 'sum by (exporter) (rate(otelcol_exporter_sent_spans[1m]))'
exporter=zipkin  35.48888888888889
exporter=otlp_grpc/jaeger  35.48888888888889
exporter=otlp_http/vendor  0
ana@obs:~/shop$ ./promq 'sum by (exporter) (otelcol_exporter_queue_size{data_type="traces"})'
exporter=otlp_grpc/jaeger  0
exporter=zipkin  0
exporter=otlp_http/vendor  28
ana@obs:~/shop$ ./promq 'sum by (exporter) (otelcol_exporter_queue_capacity{data_type="traces"})'
exporter=otlp_grpc/jaeger  1000
exporter=zipkin  1000
exporter=otlp_http/vendor  1000
ana@obs:~/shop$ docker compose logs --no-log-prefix otel-collector 2>&1 | grep 'otlp_http/vendor' | grep -m1 -o 'dial tcp: [^\"]*'
dial tcp: lookup vendor on 127.0.0.11:53: no such host
```

Jaeger and Zipkin still receive 35 spans a second. The vendor's exporter sends none, and its queue
holds 28 batches waiting to be retried, out of the 1000 it has room for; the Collector's log says
why, in the words of the network. **At this rate the queue lasts about three quarters of an hour**,
and after that the vendor's copy loses data while the others lose nothing.

Two things follow for anybody sending to a vendor. **The queue is memory**, and a long outage at the
vendor fills it and then loses data, so its size is a decision about how long an outage you can ride
out. The Collector can also keep it on disk with a storage extension. And **the queue is a metric**,
so the alert that says *the vendor has stopped accepting our data* can be written in your own
Prometheus, which keeps working when the vendor does not.

Before the next section, put the Collector back on its first configuration:

```sh
rm compose.override.yaml
docker compose up -d otel-collector
```
