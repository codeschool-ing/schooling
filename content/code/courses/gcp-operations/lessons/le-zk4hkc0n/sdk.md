---
title: Instrumenting once, with OpenTelemetry
version: 1
---

**OpenTelemetry is a vendor-neutral standard for producing traces, metrics and logs: an API your code calls,
an SDK that turns the calls into data, and a wire protocol, OTLP, that carries it.** The code says "a span
called *charge payment* started and ended" and nothing about Google. Where the span goes is decided
elsewhere, by an exporter, and that separation is what lesson 11 could not show and this one can: everything
here runs on your computer, against an OpenTelemetry Collector in a container, and the spans are real.

Two packages, into the course's virtual environment:

```sh
cd ~/gcp && source venv/bin/activate
pip install -q 'opentelemetry-sdk==1.45.0' 'opentelemetry-exporter-otlp-proto-http==1.45.0'
```

## One checkout, traced

The program below performs one of the shop's checkouts as four operations, with sleeps standing in for the
work, and traces them. Write it into `~/gcp/checkout.py`:

```python
# checkout.py
"""checkout.py: one checkout of the shop, traced with OpenTelemetry."""
import time

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

provider = TracerProvider(resource=Resource.create(
    {"service.name": "shop-api", "service.version": "a1b2c3d"}))
provider.add_span_processor(BatchSpanProcessor(
    OTLPSpanExporter(endpoint="http://localhost:4318/v1/traces")))
trace.set_tracer_provider(provider)
tracer = trace.get_tracer("shop.checkout")

with tracer.start_as_current_span("POST /orders") as root:
    root.set_attribute("order.id", "o-1001")
    with tracer.start_as_current_span("load basket"):
        time.sleep(0.02)
    with tracer.start_as_current_span("charge payment") as pay:
        pay.set_attribute("payment.provider", "pix")
        time.sleep(0.15)
    with tracer.start_as_current_span("insert order"):
        time.sleep(0.03)
    print("trace id", format(root.get_span_context().trace_id, "032x"))

provider.shutdown()
```

Read it in four steps:

- **The resource** says what produced the data: `service.name` and `service.version`, the same pair lesson 11
  wrote into `serviceContext` by hand. Every span carries it.
- **The exporter** sends spans with OTLP over HTTP to `localhost:4318`, the Collector's port, in batches.
  This is the only line that knows where the data goes, and it does not name Google.
- **The spans** are nested by the `with` blocks: the three inner ones are children of `POST /orders`, so they
  share its trace id. Attributes like `order.id` travel with the span.
- **`provider.shutdown()`** sends what is still in the batch before the program exits. Without it, a short
  program can end before its spans leave.
