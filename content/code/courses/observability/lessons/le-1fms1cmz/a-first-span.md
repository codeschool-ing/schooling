---
title: A first span, printed
version: 1
---

`first_span.py` is `no_sdk.py` with the SDK set up in front of it, using the two simplest parts
there are: a processor that exports each span as it ends, and an exporter that prints it.

```schooling-example
{
  "language": "python",
  "file": "first_span.py",
  "parts": [
    {
      "code": "from opentelemetry import trace\nfrom opentelemetry.sdk.resources import Resource\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\n\nprovider = TracerProvider(resource=Resource.create({\"service.name\": \"first-span\"}))\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))\ntrace.set_tracer_provider(provider)\n\n",
      "note": "The same three pieces as the shop's, with two swapped: the exporter prints to the terminal instead of sending, and the processor exports each span the moment it ends."
    },
    {
      "code": "tracer = trace.get_tracer(\"first-span\")\nwith tracer.start_as_current_span(\"hello\") as span:\n    print(\"recording:\", span.is_recording())",
      "note": "The code inside the `with` is exactly `no_sdk.py`'s. The span starts on entering the block and ends on leaving it, and ending is what sends it to the processor."
    }
  ]
}
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python first_span.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-d11530ae7036 Creating 
 Container shop-sandbox-run-d11530ae7036 Created 
recording: True
{
    "name": "hello",
    "context": {
        "trace_id": "0xaf4d466b3c7618bf2de7b34a82bbc28d",
        "span_id": "0x7e3af0e482e0f939",
        "trace_state": "[]"
    },
    "kind": "SpanKind.INTERNAL",
    "parent_id": null,
    "start_time": "2026-10-02T03:33:35.497358Z",
    "end_time": "2026-10-02T03:33:35.497481Z",
    "status": {
        "status_code": "UNSET"
    },
    "attributes": {},
    "events": [],
    "links": [],
    "resource": {
        "attributes": {
            "telemetry.sdk.language": "python",
            "telemetry.sdk.name": "opentelemetry",
            "telemetry.sdk.version": "1.45.0",
            "service.instance.id": "d126c213-03dc-433f-b884-a98615eadeda",
            "service.name": "first-span"
        },
        "schema_url": ""
    }
}
```

**`recording: True`**, and the finished span printed as JSON. Every field in it is something a
backend will later store, search or draw:

| field | what it holds here |
|---|---|
| `name` | `hello`, what the work is called |
| `context.trace_id` | 128 bits, random, shared by every span of one request |
| `context.span_id` | 64 bits, random, this span alone |
| `kind` | `INTERNAL`: neither end of a call between services |
| `parent_id` | `null`, so this span is the **root** of its trace |
| `start_time`, `end_time` | when it started and ended, in UTC; here 123 microseconds apart |
| `status` | `UNSET`, meaning nobody said it failed |
| `attributes`, `events`, `links` | empty; the rest of this lesson fills the first two, and lesson 4 the third |
| `resource` | who produced it: the SDK, its version and `service.name` |

Two of those fields deserve a second look. The resource carries a `service.instance.id` that
nobody set, a random id the SDK generated for this run of the program, so two copies of one
service can be told apart. And **the ids are random rather than counted**: no service needs to ask
another for a number, which is what lets a hundred processes each start traces without
coordinating.
