---
title: Changing where telemetry goes, and nothing else
version: 1
---

**Everything in `shop_trace.py` below the setup block is vendor-neutral**: spans, kinds, attributes,
statuses and exceptions are OpenTelemetry's, and no line of them mentions Azure. Sending the same spans to
Application Insights replaces the setup block and nothing else. With the distro, installed as the
`azure-monitor-opentelemetry` package, it becomes:

```python
# the setup block, with Azure Monitor's distro instead of the console exporter
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace

configure_azure_monitor()   # reads APPLICATIONINSIGHTS_CONNECTION_STRING from the environment
tracer = trace.get_tracer("shop")
```

That was **not run** here. It needs a connection string, which names a real Application Insights resource
and its ingestion endpoint, and the course has no resource to name. The connection string is not a
secret in the sense lesson 2 meant: it lets anybody holding it **send** telemetry to the resource, not read
it, which is why Microsoft documents it as safe to keep in configuration. It is still better kept out of
the repository, because a stranger who has it can fill your workspace, and your bill, with rows.

Going the other way is the same edit. Pointed at an **OpenTelemetry Collector** with the OTLP exporter, the
application does not know or care which backend is behind it; the collector can send to Azure Monitor,
to another vendor, or to both while a team compares them. Configured by environment, as the
specification defines:

```sh
export OTEL_SERVICE_NAME=shop-api
export OTEL_EXPORTER_OTLP_ENDPOINT=http://collector.internal.example:4317
```

That is the portability this lesson's title promises, and its limit is worth stating. **Instrumentation
moves; queries do not.** The KQL of lessons 10 to 12, written against `AppRequests`, means nothing to
another backend. A team that changes vendors keeps its spans and rewrites its alerts, dashboards and the
habits of the people who read them, which is most of the work.
