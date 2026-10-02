---
title: Sending spans: OTLP, and what a processor is for
version: 1
---

The console was for reading. The shop's services send their spans with **OTLP**, the OpenTelemetry
protocol, to the Collector, over HTTP on port 4318 in this lab. Nothing in the code names the
address: `OTLPSpanExporter()` reads `OTEL_EXPORTER_OTLP_ENDPOINT` from the environment, and the lab's
`compose.yaml` sets it once for every service of the shop:

```yaml
    OTEL_EXPORTER_OTLP_ENDPOINT: http://otel-collector:4318
```

That leaves the **processor**, which looked like a formality in the first script. It decides *when*
a finished span is exported, and the decision has a price. `cost.py` creates 2000 empty spans and
sends them to the Collector, once with each kind of processor:

```python
import sys
import time

from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, SimpleSpanProcessor

kind = sys.argv[1]
processor = {"simple": SimpleSpanProcessor, "batch": BatchSpanProcessor}[kind]
provider = TracerProvider(resource=Resource.create({"service.name": f"cost-{kind}"}))
provider.add_span_processor(processor(OTLPSpanExporter()))
tracer = provider.get_tracer("cost")

start = time.perf_counter()
for i in range(2000):
    with tracer.start_as_current_span("unit of work"):
        pass
print(f"{kind}: 2000 spans in {time.perf_counter() - start:.2f} s")
provider.shutdown()
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python cost.py simple
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-4b60f407ca99 Creating 
 Container shop-sandbox-run-4b60f407ca99 Created 
simple: 2000 spans in 1.85 s
ana@obs:~/shop$ docker compose run --rm sandbox python cost.py batch
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-b31b18bf4c1d Creating 
 Container shop-sandbox-run-b31b18bf4c1d Created 
batch: 2000 spans in 0.08 s
```

**1.85 seconds against 0.08**, for the same 2000 spans. The simple processor exports each span the
moment it ends, so every `with` block waited for an HTTP request to the Collector and back. That is almost a
millisecond per span, added to the code being measured. The batch processor puts the finished span
in a queue and returns. A thread of its own sends the queue in batches, every few seconds or when
enough have piled up, and the code never waits for the network.

So **the batch processor is the one for a service**, and the simple one is for a script you are
reading on a console. The batch processor has a cost of its own. It is the reason `cost.py`
ends with `provider.shutdown()`: spans waiting in the queue are lost if the process dies before the
next send. A normal exit flushes them, because the SDK registers a shutdown when the provider is
created. A process killed outright, by the kernel running out of memory or by `kill -9`, takes its
last few seconds of spans with it. Those are usually the seconds that explain why it died.

The queue is also bounded. If the Collector stops answering, the batch processor keeps a fixed
number of spans, 2048 by default in Python, and drops the rest rather than growing until the
service runs out of memory. **Losing telemetry is the right failure**; taking the service down
because its telemetry could not be delivered is the wrong one.
