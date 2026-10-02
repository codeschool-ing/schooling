---
title: Spans inside spans, and the current span
version: 1
---

One span per request says how long the request took. **Spans inside it say where the time went**,
and in lesson 1 that was the whole answer. `nested.py` prices a basket of two products, with one
span for the basket and one per lookup, and prints each finished span on one line:

```schooling-example
{
  "language": "python",
  "file": "nested.py",
  "parts": [
    {
      "code": "import time\n\nfrom opentelemetry import trace\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\n\n\ndef one_line(span):\n    parent = format(span.parent.span_id, \"016x\") if span.parent else \"none\"\n    took = (span.end_time - span.start_time) / 1e6\n    return f\"{span.name:<16} span {span.context.span_id:016x}  parent {parent:<16}  {took:5.1f} ms\\n\"\n\n\nprovider = TracerProvider()\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter(formatter=one_line)))\ntrace.set_tracer_provider(provider)\ntracer = trace.get_tracer(\"nested\")\n\nPRICES = {\"tea-500g\": 3450, \"kettle\": 18990}\n\n\n",
      "note": "A formatter so the console prints one line per span: its name, its id, its parent's id and how long it took. Times are kept in nanoseconds, hence the division by a million."
    },
    {
      "code": "def price(sku):\n    with tracer.start_as_current_span(\"look up price\") as span:\n        span.set_attribute(\"shop.sku\", sku)\n        time.sleep(0.01)\n        return PRICES[sku]\n\n\n",
      "note": "**Nothing here names a parent.** `start_as_current_span` makes the new span a child of whatever span is current, and the caller decides which one that is."
    },
    {
      "code": "with tracer.start_as_current_span(\"price basket\"):\n    total = price(\"tea-500g\") + price(\"kettle\")\nprint(\"total:\", total)",
      "note": "Both calls happen while `price basket` is current, so both lookups become its children."
    }
  ]
}
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python nested.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-829101598f1e Creating 
 Container shop-sandbox-run-829101598f1e Created 
look up price    span 643cd2d47d78e040  parent e087853aa9ca2388   10.2 ms
look up price    span ae91b9a9c550a10e  parent e087853aa9ca2388   10.2 ms
price basket     span e087853aa9ca2388  parent none               20.7 ms
total: 22440
```

The two lookups carry **the basket's span id as their parent**, and the basket has none: it is the
root. That is all a trace's shape is, ids pointing at ids, and a backend rebuilds the tree from them
whatever order the spans arrive in. Here they arrived children first, because a span is exported
when it ends and the basket could only end after both lookups had. The times nest too: 20.7
milliseconds for the basket, around two lookups of 10.2.

**The parent was never passed.** `price()` has no argument for it. OpenTelemetry keeps a *current
span*, the one whose `with` block the code is inside. `start_as_current_span` both reads it to
pick the parent and replaces it for the duration of its own block. In Python the current span lives
in a `contextvars` variable, so it follows a function call naturally and an `asyncio` task takes a
copy when it is created. **A new thread does not**: it starts with no current span, which is one of
the commonest ways to lose a parent inside a single service.

That convenience has an edge, and it is exactly where a service meets another one. The current span
lives in this process's memory. A request to another service, a message on a queue or a job
started by a timer carries none of it unless something writes the ids into the request itself.
Lesson 4 is about that something, and lesson 1's trace already showed it working: the storefront,
orders, payments and mailer are four processes, and one trace.
