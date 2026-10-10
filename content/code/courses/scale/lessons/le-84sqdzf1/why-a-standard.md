---
title: Why telemetry needed a standard
version: 1
---

Lesson 7 instrumented the box office with `prometheus_client`, a library that speaks one format to
one system. That is how instrumentation used to be done everywhere, and it has a cost that only
shows later: **the code that records the signals is tied to the product that stores them.** A team
that moves from one monitoring vendor to another rewrites the instrumentation of every service; a
library that wants to emit traces has to pick a vendor for all its users; and a request that crosses
two services written by two teams, with two vendors' libraries, cannot be followed at all, because
the two do not agree on how to pass a trace from one to the other.

**OpenTelemetry** is the answer the industry converged on, under the Cloud Native Computing
Foundation, out of two earlier projects, OpenTracing and OpenCensus. It standardises the part of
observability that lives in your code, and leaves the storage and the screens to whoever you choose:

- **an API** that code calls to create spans, record metrics and write logs, the same in every
  language;
- **an SDK** per language that implements it: sampling, batching, and exporting;
- **OTLP**, the OpenTelemetry protocol, the one format every piece speaks on the wire;
- **the Collector**, a program that receives telemetry over OTLP and many other formats, processes
  it, and sends it to one or several back ends;
- **semantic conventions**, agreed names for common attributes, like `http.route` and
  `http.response.status_code`, so that every service describes an HTTP request the same way.

What it does not include is a database or a user interface. Traces go to Jaeger, Tempo, Zipkin or a
hosted service; metrics to Prometheus or a hosted service; logs to whatever stores logs. **Changing
the back end is a change to the Collector's configuration, and not to any service's code.**

This lesson adds a second service to the box office, so that a request crosses a process boundary,
traces both with OpenTelemetry, and reads the result in Jaeger.
