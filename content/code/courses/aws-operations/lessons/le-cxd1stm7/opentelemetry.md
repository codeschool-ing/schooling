---
title: OpenTelemetry, and tracing that is not tied to one vendor
version: 1
---

The X-Ray SDKs were AWS's own way to instrument a service, one per language, and they speak only X-Ray.
**OpenTelemetry** is the open standard that replaced most vendors' own SDKs: one API to create spans,
one wire format, OTLP, and exporters to any backend that speaks it, X-Ray included. AWS now recommends
OpenTelemetry for new instrumentation, and has announced that its X-Ray SDKs and daemon are moving to
maintenance; read the dates on AWS's own announcement before planning around them.

The pieces line up with this lesson's vocabulary under other names:

| OpenTelemetry | X-Ray |
|---|---|
| span | segment or subsegment |
| trace id (32 hex digits) | trace id (`1-` time, random part) |
| `traceparent` header, W3C Trace Context | `X-Amzn-Trace-Id` header |
| collector | X-Ray daemon |

## The collector

A service using the OpenTelemetry SDK sends its spans to a **collector**, a separate process beside it,
which batches them, adds attributes such as the region and the cluster, and exports them. AWS publishes
its own build, the **AWS Distro for OpenTelemetry**, with the X-Ray exporter in it. A collector's
configuration is three lists, receivers, processors and exporters, joined into a pipeline:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:
    timeout: 5s

exporters:
  awsxray:
    region: sa-east-1

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [awsxray]
```

The service sends OTLP to port 4317; the collector batches for five seconds and hands the spans to X-Ray,
which converts the trace ids into its own format. **That collector was not run for this course**: the X-Ray
it would send to is moto's, which accepts segments through the X-Ray API and has no OTLP endpoint.

## Why the standard matters to operations

- **one instrumentation, any backend**: changing tracing vendor is a collector change, not a change to
  every service;
- **one header across languages and clouds**: a Go service and a Python one, or AWS and another provider,
  continue the same trace;
- **metrics and logs from the same SDK**, with the trace id attached to both, which is the join the
  previous section asked for.

The cost of a collector is one more process to run and watch per host or per task, usually as a
sidecar container beside the service in the same ECS task.
