---
title: Deciding at the tail
version: 2
---

**Tail sampling decides after the trace has ended**, so it can decide on what happened. The services
go back to recording every trace, and the Collector holds each one until it is complete, then keeps
it if any of its policies says so. The configuration that does it is a third file for the Collector. Save it whole:

`~/shop/otel/collector-sampling.yaml`

```yaml
# The Collector of collector.yaml, deciding which traces to keep (lesson 12).
# Every span still feeds the span metrics; only the traces worth reading go
# on to Jaeger and Zipkin.
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  fluent_forward:
    endpoint: 0.0.0.0:24224

connectors:
  # Rate, errors and duration per service and span name, computed from every
  # span before any of them is dropped.
  spanmetrics:
    metrics_flush_interval: 15s
    histogram:
      explicit:
        buckets: [10ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s]

processors:
  # Wait until a trace has had time to finish, then keep it if any policy says so.
  tail_sampling:
    decision_wait: 10s
    num_traces: 20000
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow
        type: latency
        latency: {threshold_ms: 1000}
      - name: a-few-of-the-rest
        type: probabilistic
        probabilistic: {sampling_percentage: 5}
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
  otlp_http/prometheus:
    endpoint: http://prometheus:9090/api/v1/otlp

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
    traces/all:
      receivers: [otlp]
      processors: [memory_limiter]
      exporters: [spanmetrics]
    traces:
      receivers: [otlp]
      processors: [memory_limiter, tail_sampling, batch]
      exporters: [otlp_grpc/jaeger, zipkin]
    metrics/spans:
      receivers: [spanmetrics]
      processors: [batch]
      exporters: [otlp_http/prometheus]
    logs:
      receivers: [fluent_forward]
      processors: [memory_limiter, transform/logs, groupbyattrs/service, transform/service, batch]
      exporters: [otlp_http/loki]
```

Its `tail_sampling` processor has three policies:

```
ana@obs:~/shop$ sed -n '/^  tail_sampling:/,/^  memory_limiter:/p' otel/collector-sampling.yaml
  tail_sampling:
    decision_wait: 10s
    num_traces: 20000
    policies:
      - name: errors
        type: status_code
        status_code: {status_codes: [ERROR]}
      - name: slow
        type: latency
        latency: {threshold_ms: 1000}
      - name: a-few-of-the-rest
        type: probabilistic
        probabilistic: {sampling_percentage: 5}
  memory_limiter:
```

- **`errors`**: any span with an error status keeps the whole trace.
- **`slow`**: a trace longer than one second is kept.
- **`a-few-of-the-rest`**: 5% of everything, so that there are ordinary traces to compare the
  slow ones with. Without a baseline, every trace in the store is a problem and nobody can say what
  normal looks like.

`decision_wait` is how long the Collector waits after a trace's first span before deciding. To give
the policies something to find, payments is told to add 1500 ms to every twenty-fifth charge and to
fail every fortieth. The storefront and orders lose their samplers, the Collector moves to the new
file, and Prometheus gains two
flags: one stores exemplars, as in lesson 11, and the other lets the Collector send it the metrics
of the section on span metrics. All of it is one override, replacing the last:

`~/shop/compose.override.yaml`

```yaml
services:
  otel-collector:
    volumes: ["./otel/collector-sampling.yaml:/etc/otelcol/config.yaml:ro"]
  prometheus:
    command: [--config.file=/etc/prometheus/prometheus.yml, --web.enable-lifecycle,
              --storage.tsdb.path=/prometheus, --enable-feature=exemplar-storage,
              --web.enable-otlp-receiver]
```

```sh
echo '{"latency_ms": 50, "slow_every": 25, "slow_ms": 1500, "fail_every": 40}' > faults/payments.json
docker compose up -d storefront orders otel-collector prometheus
sleep 150
```

After two minutes, the Collector's own metrics say what each policy kept:

```
ana@obs:~/shop$ ./promq 'sum by (policy) (increase(otelcol_processor_tail_sampling_count_traces_sampled{decision="sampled"}[2m]))'
policy=a-few-of-the-rest  34.285714285714285
policy=errors  13.714285714285714
policy=slow  21.71428571428571
```

```
ana@obs:~/shop$ ./promq 'sum by (decision) (increase(otelcol_processor_tail_sampling_global_count_traces_sampled[2m]))'
decision=not_sampled  475.4285714285714
decision=sampled  65.14285714285714
```

About 540 checkouts in two minutes, and 65 kept, 12%. `errors` kept 14, which is every fortieth
charge; `slow` kept 22, every twenty-fifth; `a-few-of-the-rest` kept 34, near its 5%. The three add up
to more than 65 because a trace can satisfy two policies at once, and the counts are fractional
because `increase` extrapolates to the edges of its window, as lesson 5 showed.

And what that does to the volume:

```
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_receiver_accepted_spans[1m]))'
  39.86666666666666
ana@obs:~/shop$ ./promq 'sum(rate(otelcol_exporter_sent_spans{exporter="zipkin"}[1m]))'
  4.933333333333334
```

Forty spans a second arrive and five leave. **The traces in the store are now the ones worth
opening**. A search in Jaeger for errors finds every error of the last two minutes, and a search for
slow checkouts finds every slow one, not one in ten.

The policies are evaluated together and any one of them is enough. The processor has more types than
these three: on an attribute's value, on a span count, on the rate per second, and combinations of
them. A policy on an attribute is how a team keeps every trace of one important customer, or of one
new release, for a week.
