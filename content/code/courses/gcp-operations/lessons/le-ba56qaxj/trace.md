---
title: Cloud Trace, and following one request
version: 1
---

**A trace is the record of one request as it crossed the system: a tree of spans, each one an operation
with a start, an end and the span that called it.** The shop's checkout calls the API, which calls the
payment service and the database; a trace of one checkout shows the four as nested bars on a time axis, and
which bar took the time. Metrics say the p99 is 2.4 seconds; a trace of one of those slow requests says where
the 2.4 seconds went. Cloud Trace stores and draws traces, and **this section was not run**: Cloud Trace has
no emulator. Lesson 12 produces real traces on your computer, with OpenTelemetry, and shows their spans.

## How a request carries its trace

A trace survives from one service to the next only because each request carries its id in a header. The
standard header is `traceparent`, from the W3C Trace Context specification:

```localised
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
             │  └──────── trace id ──────────────┘ └ parent span ─┘ └ sampled
             └ version
```

Google's load balancers and Cloud Run read it, add their own span, and pass it on; Google Cloud also
accepts its older header, `X-Cloud-Trace-Context`. **A service that does not forward the header breaks the
trace in two**, and the second half starts a new trace that nobody connects to the first. This is the
commonest reason a trace stops at a service boundary.

## From a log line to its trace

Lesson 9's first log line carried:

```json
{"logging.googleapis.com/trace": "projects/planner-dev/traces/4bf92f3577b34da6a3ce929d0e0e4736"}
```

The value is the trace id from the header above, written as a resource name. Cloud Logging shows such an
entry with a link to the trace, and Cloud Trace shows, beside each span, the log entries written during it.
That pairing is what turns "order o-1001 was slow" into the trace of order o-1001, and it costs one field in a
log line the program was writing anyway.

## Sampling, and what it costs

Not every request is traced. The **sampling decision** is the last field of `traceparent`, `01` for sampled,
made once at the start of the request and respected by every service after it, so that a trace is either
whole or absent. Cloud Run samples a small share of requests on its own; a program instrumented with
OpenTelemetry decides with its sampler (lesson 12).

From the pricing page, read on 30 October 2026, Cloud Trace charges **0.20 USD per million spans** after the
first 2.5 million per billing account each month. The shop's checkout is about four spans; at forty checkouts
a minute and every one traced, that is 40 × 4 × 60 × 730 = 7,008,000 spans a month, 4.5 million above the
free allowance, or about 0.90 USD. Sampling one request in ten keeps it inside the allowance.
