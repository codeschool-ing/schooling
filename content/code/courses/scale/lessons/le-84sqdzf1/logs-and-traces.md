---
title: From a log line to its trace
version: 1
---

Lesson 7 said a metric shows that something is wrong, a trace shows where, and a log shows what
exactly. Those three only work together if one can be reached from another, and the link between a
log line and its trace is the **trace id**.

Every log line the box office writes inside a request now carries one. From the capture of the last
section:

```
{"time": "2026-10-10T06:22:21.113+00:00", "level": "info", "message": "request", "host": "dd4bf75a071b", "method": "POST", "route": "/events/{id}/tickets", "status": 201, "ms": 46.2, "trace_id": "5bd86167ca0ed7a647e37c1ebe501aac"}
```

That `trace_id` is the one in payments' `traceparent`, and the one Jaeger files the trace under. In
practice the move goes in both directions:

- **from a log line to a trace**: an error in the log, and you want to see what else that request was
  doing, in which service, and how long each part took. The trace id finds it in Jaeger, whose page
  has a search box for exactly this, and whose API takes the id in the address,
  `/api/v3/traces/<trace id>`;
- **from a trace to its log lines**: a slow span in a trace, and you want to know what the code
  logged while it ran. The trace id, searched in the logs, returns every line of that request, from
  every service that wrote one.

## Exemplars

Metrics can carry the link too. An **exemplar** is a trace id attached to one observation of a
histogram: of the requests in the 100 to 250 ms bucket, here is one, and here is its trace.
Prometheus stores exemplars when the client sends them, and a dashboard can then show, beside a
slow percentile, a button to the trace of a request that was slow. It closes the loop of lesson 7:
**the metric that says something is slow points at one request that was.**

The box office's metrics do not send exemplars; `prometheus_client` can, given a trace id per
observation, and OpenTelemetry's own metrics SDK does it by itself when a span is current.
