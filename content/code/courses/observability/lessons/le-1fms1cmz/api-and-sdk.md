---
title: The API, the SDK, and why nothing happens without the second
version: 2
---

The obvious picture of instrumenting is one library: import it, create spans, and they appear
somewhere. **OpenTelemetry is two pieces on purpose**, and the first script shows why. `no_sdk.py`
imports only the API, asks for a tracer and opens a span:

```python
from opentelemetry import trace

tracer = trace.get_tracer("no-sdk")
with tracer.start_as_current_span("hello") as span:
    print("recording:", span.is_recording())
    print("trace id:", format(span.get_span_context().trace_id, "032x"))
```

Save it as `~/shop/scratch/no_sdk.py`. **Every script this course runs lives in `~/shop/scratch`**,
and runs in `sandbox`, a container from the shop's own image whose working directory is that one,
so the script has the same packages the services have. Docker prints three lines of its own before
the script's output, saying it created the container:

```
ana@obs:~/shop$ docker compose run --rm sandbox python no_sdk.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-a21f65582056 Creating 
 Container shop-sandbox-run-a21f65582056 Created 
recording: False
trace id: 00000000000000000000000000000000
```

**No error, and nothing recorded.** The span exists, the code ran, and the trace id is zero: a span
that is not part of any trace. That is the API doing exactly what it promises. Without an SDK it
hands back spans that do nothing, cheaply. That means a library can be instrumented once and shipped to
people who never set OpenTelemetry up, at almost no cost to them.

The **SDK** is what makes the calls real, and it is set up once, when the program starts. It has
three parts, and the shop's storefront and payments share one function that assembles them:

```schooling-example
{
  "language": "python",
  "file": "common/tracing.py",
  "parts": [
    {
      "code": "\"\"\"The OpenTelemetry SDK, set up by hand, for the services instrumented by hand.\"\"\"\nfrom opentelemetry import trace\nfrom opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter\nfrom opentelemetry.sdk.resources import Resource\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import BatchSpanProcessor\n\n",
      "note": "Everything imported from `opentelemetry.sdk` is the SDK. Only `trace`, the first import, is the API, and it is the only one the rest of the service uses."
    },
    {
      "code": "def setup(service, version):\n    resource = Resource.create({\"service.name\": service, \"service.version\": version})\n",
      "note": "**The resource** describes who is producing the spans, and every span this process sends carries it. `service.name` is the one attribute every backend groups by."
    },
    {
      "code": "    provider = TracerProvider(resource=resource)\n    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))\n",
      "note": "**The provider makes real spans**, and each finished one goes to the processor, which hands it to the exporter. `OTLPSpanExporter()` reads where to send from the environment, `OTEL_EXPORTER_OTLP_ENDPOINT`, which the lab sets to the Collector."
    },
    {
      "code": "    trace.set_tracer_provider(provider)\n    return trace.get_tracer(service, version)",
      "note": "Registering the provider with the API is the switch: from here on, every `get_tracer` in the process, in this code or in any library, returns tracers that record."
    }
  ]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The pieces between a line of code and the Collector. Your code calls the API: get_tracer and start_as_current_span. Without an SDK installed, the API hands back spans that record nothing. With one, the TracerProvider, which carries the resource such as service.name, creates real spans; each finished span goes to a span processor, Simple or Batch, which hands it to an exporter, Console or OTLP; the OTLP exporter sends it to the Collector.\"><defs><marker id=\"sdk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"130\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">your code</text><text x=\"85.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">start_as_current_span</text><rect x=\"180\" y=\"70\" width=\"130\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TracerProvider</text><text x=\"245.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resource:</text><text x=\"245.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">service.name</text><rect x=\"340\" y=\"70\" width=\"110\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">processor</text><text x=\"395.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Simple or Batch</text><rect x=\"480\" y=\"70\" width=\"110\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">exporter</text><text x=\"535.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Console or OTLP</text><rect x=\"620\" y=\"70\" width=\"90\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"665.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Collector</text><path d=\"M152 110 L178 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sdk-ah)\"></path><path d=\"M312 110 L338 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sdk-ah)\"></path><path d=\"M452 110 L478 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sdk-ah)\"></path><path d=\"M592 110 L618 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sdk-ah)\"></path><path d=\"M165 165 L165 205 L595 205 L595 165\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"380\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the SDK, set up once at start-up</text><path d=\"M85 165 L85 205\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"85\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the API</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">from a span in your code to the Collector</text></svg>", "caption": "The API is what instrumented code depends on; everything to its right is the SDK, set up once when the program starts. Swap any box on the right and the instrumented code does not change."}
```

That split decides how the rest of this course is written. Instrumentation, the calls that create
spans and set attributes, depends on the API alone and is written beside the code it describes.
Where the spans go is configuration, written once, and lessons 3, 11 and 13 change it without
touching a line of instrumentation.

The API defines more than traces: the same split exists for **metrics**, with meters and
instruments, and for logs. The shop exposes its metrics in Prometheus's own format instead, for a
reason lesson 5 gives, so this lesson stays with spans.
