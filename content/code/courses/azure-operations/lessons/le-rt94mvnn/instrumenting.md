---
title: A checkout, instrumented by hand
version: 1
---

The SDK goes into the same virtual environment as the command line, pinned:

```sh
cd ~/azure && source venv/bin/activate
pip install -q 'opentelemetry-sdk==1.45.1'
mkdir -p ~/azure/otel && cd ~/azure/otel
```

```
ana@laptop:~/azure/otel$ pip list 2>/dev/null | grep opentelemetry
opentelemetry-api                              1.45.1
opentelemetry-sdk                              1.45.1
opentelemetry-semantic-conventions             0.66b1
```

This is a checkout handler reduced to its calls, instrumented with OpenTelemetry and nothing else. Save
it as `shop_trace.py`:

```schooling-example
{
  "language": "python",
  "file": "shop_trace.py",
  "parts": [
    {
      "code": "# shop_trace.py: one checkout, traced with OpenTelemetry, printed to the terminal\nimport time\n\nfrom opentelemetry import trace\nfrom opentelemetry.sdk.resources import Resource\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\nfrom opentelemetry.trace import SpanKind, Status, StatusCode\n\n",
      "note": "The API (`opentelemetry.trace`) and the SDK (`opentelemetry.sdk`) are separate imports, as they are separate packages: a library you depend on can use the API without choosing an SDK for you."
    },
    {
      "code": "def one_line(span):\n    parent = f\"{span.parent.span_id:016x}\"[:8] if span.parent else \"-\"\n    ms = (span.end_time - span.start_time) / 1e6\n    return (f\"trace {span.context.trace_id:032x}\"[:14] + f\"  span {span.context.span_id:016x}\"[:15]\n            + f\"  parent {parent:<8}  {span.kind.name:<6}  {span.name:<16}  {span.status.status_code.name:<5}  {ms:4.0f} ms\\n\")\n\n",
      "note": "The console exporter takes a formatter. This one prints a span on one line, with the ids cut to eight hexadecimal digits so the three fit; the full ids are 32 and 16 digits."
    },
    {
      "code": "provider = TracerProvider(resource=Resource.create({\"service.name\": \"shop-api\"}))\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter(formatter=one_line)))\ntrace.set_tracer_provider(provider)\ntracer = trace.get_tracer(\"shop\")\n\n",
      "note": "The setup: a provider with a **resource** naming the service, a processor that exports each span as it ends, and a tracer. This block is the only part that knows where telemetry goes."
    },
    {
      "code": "def insert_order(order_id, slow):\n    with tracer.start_as_current_span(\"INSERT orders\", kind=SpanKind.CLIENT) as span:\n        span.set_attribute(\"db.system\", \"mssql\")\n        span.set_attribute(\"server.address\", \"sql-shop.database.windows.net\")\n        time.sleep(0.3 if slow else 0.02)\n        if slow:\n            span.set_status(Status(StatusCode.ERROR, \"timeout\"))\n            raise TimeoutError(\"Execution Timeout Expired\")\n\n",
      "note": "A `CLIENT` span for the database call, with the semantic-convention attributes for a database. On a timeout it sets its status to `ERROR` and raises, as a real driver would."
    },
    {
      "code": "def charge(order_id):\n    with tracer.start_as_current_span(\"POST /v1/charges\", kind=SpanKind.CLIENT) as span:\n        span.set_attribute(\"server.address\", \"api.payments.example\")\n        span.set_attribute(\"http.response.status_code\", 201)\n        time.sleep(0.01)\n\n",
      "note": "A second `CLIENT` span, for the payment provider."
    },
    {
      "code": "def checkout(order_id, slow=False):\n    with tracer.start_as_current_span(\"POST /checkout\", kind=SpanKind.SERVER) as span:\n        span.set_attribute(\"http.route\", \"/checkout\")\n        try:\n            insert_order(order_id, slow)\n            charge(order_id)\n            span.set_attribute(\"http.response.status_code\", 200)\n        except TimeoutError as error:\n            span.record_exception(error)\n            span.set_attribute(\"http.response.status_code\", 500)\n            span.set_status(Status(StatusCode.ERROR))\n\n",
      "note": "The `SERVER` span wraps the whole request. Spans started inside it become its children automatically, through the current context. A caught exception is recorded on the span as an event, and the status becomes `ERROR`."
    },
    {
      "code": "checkout(1042)\ncheckout(1043, slow=True)\n",
      "note": "Two checkouts: one that works, and one whose database call times out, like Thursday's."
    }
  ]
}
```

```
ana@laptop:~/azure/otel$ python3 shop_trace.py
trace 14c02459  span b2a632cc  parent 2d0299a3  CLIENT  INSERT orders     UNSET    20 ms
trace 14c02459  span a90226f9  parent 2d0299a3  CLIENT  POST /v1/charges  UNSET    10 ms
trace 14c02459  span 2d0299a3  parent -         SERVER  POST /checkout    UNSET    31 ms
trace 6a846832  span 292d70e8  parent 4a03e700  CLIENT  INSERT orders     ERROR   302 ms
trace 6a846832  span 4a03e700  parent -         SERVER  POST /checkout    ERROR   302 ms
```

Your ids and durations will differ; they are random and measured on every run. Read the lines for their
structure instead. **The spans are printed as they end**, so the children come before their parent. The
first three share a trace id, and both `CLIENT` spans name the `SERVER` span as their parent: one trace,
one request, two calls. The last two are the slow checkout: its `INSERT orders` ended in `ERROR` after
300 ms, there is no payment span because the code never reached it, and the `SERVER` span is `ERROR` too.
That is lesson 11's first failed checkout, told by the application itself.

`SimpleSpanProcessor` exports each span the moment it ends, which suits a demonstration. A real service
uses `BatchSpanProcessor`, which queues spans and sends them in batches from a background thread, so a
slow exporter never slows a request down.
