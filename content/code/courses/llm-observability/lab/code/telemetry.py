"""telemetry.py: where the assistant's spans go, and the clock they are stamped with.

    import telemetry
    telemetry.setup("spans.jsonl")          # once, at start-up
    with telemetry.span("search") as s:     # every step
        s.set_attribute("search.k", 3)

Every span is written to a JSON-lines file, one span per line, as it ends. If
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT is set, the same spans also go there over
OTLP/HTTP, which is how they reach Phoenix and Langfuse in lessons 6 and 7.
"""
import contextlib
import contextvars
import json
import os
import time

from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import (BatchSpanProcessor, SimpleSpanProcessor, SpanExporter,
                                            SpanExportResult)
from opentelemetry.trace import Status, StatusCode

# replay.py plays a week of traffic in a few minutes. It sets this offset so
# that each request's spans carry the moment the traffic file gives it; the
# durations inside them are measured, never shifted.
OFFSET_NS = contextvars.ContextVar("offset_ns", default=0)


def now_ns():
    return time.time_ns() + OFFSET_NS.get()


class JsonlExporter(SpanExporter):
    """One line per finished span: ids, name, times in nanoseconds, status, attributes, events."""

    def __init__(self, path):
        self.path = path

    def export(self, spans):
        with open(self.path, "a") as f:
            for s in spans:
                f.write(json.dumps({
                    "trace": f"{s.context.trace_id:032x}", "span": f"{s.context.span_id:016x}",
                    "parent": f"{s.parent.span_id:016x}" if s.parent else None,
                    "name": s.name, "start": s.start_time, "end": s.end_time,
                    "status": s.status.status_code.name, "error": s.status.description,
                    "attributes": dict(s.attributes),
                    "events": [{"name": e.name, "at": e.timestamp, "attributes": dict(e.attributes)}
                               for e in s.events]}, ensure_ascii=False) + "\n")
        return SpanExportResult.SUCCESS


def setup(path="spans.jsonl", service="assistant", processors=()):
    provider = TracerProvider(resource=Resource.create({"service.name": service}))
    for p in processors:  # lesson 2's redaction goes here, before any exporter sees a span
        provider.add_span_processor(p)
    provider.add_span_processor(SimpleSpanProcessor(JsonlExporter(path)))
    if os.environ.get("OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"):
        from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
    trace.set_tracer_provider(provider)
    return provider


tracer = trace.get_tracer("marginalia.assistant")


@contextlib.contextmanager
def span(name, **attributes):
    """A span stamped with the lab's clock, marked as an error if the block raises."""
    s = tracer.start_span(name, attributes=attributes or None, start_time=now_ns())
    with trace.use_span(s, end_on_exit=False):
        try:
            yield s
        except BaseException as e:
            s.set_status(Status(StatusCode.ERROR, f"{type(e).__name__}: {e}"))
            s.record_exception(e, timestamp=now_ns())
            raise
        finally:
            s.end(end_time=now_ns())


def event(name, **attributes):
    trace.get_current_span().add_event(name, attributes, timestamp=now_ns())
