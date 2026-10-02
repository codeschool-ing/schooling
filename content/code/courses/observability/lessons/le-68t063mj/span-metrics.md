---
title: Counting before dropping
version: 1
---

Once nine in ten traces are gone, the traces can no longer be counted. A dashboard of *checkouts per
second* built from the store would show a tenth of the truth with head sampling. With tail sampling
it would show something stranger: **almost every error and slow request, and 5% of the rest**, so
the error ratio computed from it would be several times too high.

The answer is to count first. The Collector's **`spanmetrics` connector** reads every span before the
sampler sees it and turns them into rate, error and duration metrics, one series per service, span
name, kind and status. A connector is an exporter of one pipeline and a receiver of another, and here
it ends a pipeline that takes every span and starts one that sends metrics to Prometheus:

```
ana@obs:~/shop$ sed -n '/^connectors:/,/^processors:/p' otel/collector-sampling.yaml
connectors:
  # Rate, errors and duration per service and span name, computed from every
  # span before any of them is dropped.
  spanmetrics:
    metrics_flush_interval: 15s
    histogram:
      explicit:
        buckets: [10ms, 50ms, 100ms, 250ms, 500ms, 1s, 2.5s, 5s]

processors:
```

From those metrics, the storefront's checkouts per second, by status:

```
ana@obs:~/shop$ ./promq 'sum by (span_name, status_code) (rate(traces_span_metrics_calls_total{service_name="storefront"}[1m]))'
span_name=POST /checkout status_code=STATUS_CODE_ERROR  0.1111086420301771
span_name=POST /checkout status_code=STATUS_CODE_UNSET  4.399902224395013
```

Against the storefront's own counter, measured in its code:

```
ana@obs:~/shop$ ./promq 'sum by (code) (rate(http_server_requests_total{job="storefront",route="/checkout"}[1m]))'
code=201  4.155555555555555
code=402  0.2222222222222222
code=503  0
code=502  0.1111111111111111
```

The two agree: 4.51 checkouts a second from the spans, 4.49 from the counter, and the 0.11 a
second that are errors are the storefront's 502s. The declined cards, 402, are not errors to a
span, because the request was answered correctly. And because the histogram is built from every span, its percentiles include every
slow checkout:

```
ana@obs:~/shop$ ./promq 'histogram_quantile(0.99, sum by (le) (rate(traces_span_metrics_duration_milliseconds_bucket{service_name="storefront",span_name="POST /checkout"}[2m])))'
  2126.5789473684235
```

About 2.1 seconds, the twenty-fifth charge that waits 1.5 s more. The figure is right because it
counts every checkout: the slow ones are 4% of traffic, and the kept traces, a third of them slow,
would put the 99th percentile far too high.

Two consequences worth knowing. **The series are one per span name**, so a span named after an order
id, the mistake lesson 2 warned about, becomes one series per order here, and the bill lesson 6
described. And spans give these metrics for free, which makes them tempting as a replacement for
metrics written in code. They are good for rate, errors and duration of what is traced, and blind to
everything a span does not carry, like a queue's depth or a pool's size.