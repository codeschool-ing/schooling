---
title: Inject on the way out, extract on the way in
version: 1
---

Two operations do all of it, and they are called the same in every language OpenTelemetry supports.
**Inject** writes the current context into whatever carries the request. **Extract** reads it back on
the other side and hands over a context to start spans in. The object that knows the header's format
is a **propagator**, and `opentelemetry.propagate` uses the ones `OTEL_PROPAGATORS` named.

The storefront, instrumented by hand, injects before calling `orders`:

```schooling-example
{
  "language": "python",
  "file": "storefront/app.py",
  "parts": [
    {
      "code": "        headers = {}\n        propagate.inject(headers)\n",
      "note": "**Inject**: the propagator writes the current span's context into a dictionary, as the `traceparent` header. The current span here is `POST /checkout`."
    },
    {
      "code": "        try:\n            answer = requests.post(\n                f\"{ORDERS}/orders\",\n                json={\"sku\": sku, \"qty\": qty, \"total_cents\": total, \"card\": body[\"card\"]},\n                headers=headers,\n                timeout=5,\n            )",
      "note": "The dictionary travels as HTTP headers. Nothing else in the request has to know about tracing."
    }
  ]
}
```

And payments extracts when a charge arrives:

```schooling-example
{
  "language": "python",
  "file": "payments/app.py",
  "parts": [
    {
      "code": "@app.post(\"/charge\")\ndef charge():\n    ctx = propagate.extract(request.headers)\n",
      "note": "**Extract**: the propagator reads `traceparent` from the incoming headers and returns a context holding the caller's span as a remote parent. If the header is missing, the context is empty."
    },
    {
      "code": "    with tracer.start_as_current_span(\"POST /charge\", context=ctx, kind=SpanKind.SERVER) as span:",
      "note": "`context=ctx` is what makes the new span a child of the caller instead of a root. It is the one argument the next section deletes."
    }
  ]
}
```

**`orders` does neither, and still both happen.** Flask's instrumentation extracts the incoming
header before the handler runs, which is why `POST /orders` came out as the storefront's child in
the previous section. The instrumentation of `requests` injects into every outgoing call, which is
how payments receives a `traceparent` from a service whose code never mentions one. Automatic
instrumentation is at its most useful exactly here: propagation is the same few lines on every
call, and forgetting them once breaks the trace.

So the rule for a service is simple to state: **every way a request leaves must inject, and every
way one arrives must extract.** HTTP is covered by the instrumentations. What is not covered is every
other carrier: a message on a queue, a row a job will read later, a file dropped for another
program. Each of those is a place where somebody has to write the two calls by hand or install the
instrumentation that does.
