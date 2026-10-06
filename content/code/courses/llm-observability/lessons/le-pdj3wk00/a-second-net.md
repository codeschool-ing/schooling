---
title: A second net, for spans you did not write
version: 1
---

`redact()` in `assistant.py` covers the attributes the assistant writes. It does nothing for the spans
other code writes, and lesson 1 showed an instrumentation library writing the whole prompt and the
whole reply on its own. The second net sits where every span passes, whoever made it: **the
exporter**.

`leak.py` sends one customer message through the OpenAI SDK with OpenInference instrumenting it, and
writes the spans either straight to a file or through a wrapper that redacts every string attribute
first:

```schooling-example
{
  "language": "python",
  "file": "leak.py",
  "parts": [
    {
      "code": "\"\"\"leak.py: one customer message through an instrumented SDK, with and without a redacting exporter.\"\"\"\nimport sys\n\nfrom openai import OpenAI\nfrom openinference.instrumentation.openai import OpenAIInstrumentor\nfrom opentelemetry.sdk.trace import ReadableSpan, TracerProvider\nfrom opentelemetry.sdk.trace.export import SimpleSpanProcessor, SpanExporter\n\nimport redact\nimport telemetry"
    },
    {
      "code": "class Redacting(SpanExporter):\n    \"\"\"Hands every span on to INNER with each string attribute, and each event's, passed through redact().\"\"\"\n\n    def __init__(self, inner):\n        self.inner = inner\n\n    def export(self, spans):\n        clean = lambda attrs: {k: redact.redact(v) if isinstance(v, str) else v for k, v in attrs.items()}\n        return self.inner.export([ReadableSpan(\n            name=s.name, context=s.context, parent=s.parent, resource=s.resource,\n            attributes=clean(s.attributes), links=s.links, kind=s.kind, status=s.status,\n            events=[type(e)(e.name, clean(e.attributes), e.timestamp) for e in s.events],\n            start_time=s.start_time, end_time=s.end_time, instrumentation_scope=s.instrumentation_scope)\n            for s in spans])\n\n    def shutdown(self):\n        self.inner.shutdown()",
      "note": "The wrapper: a class that is itself an exporter, holding the real one. It changes nothing about how spans are made, only what is handed on. For every span, a copy with each string attribute passed through `redact()`, and the same for each event's attributes, because an exception's message is an event and can quote the prompt. Ids, times and status are copied as they are."
    },
    {
      "code": "out = sys.argv[1]\nexporter = telemetry.JsonlExporter(out)\nif \"--redact\" in sys.argv:\n    exporter = Redacting(exporter)\nprovider = TracerProvider()\nprovider.add_span_processor(SimpleSpanProcessor(exporter))\nOpenAIInstrumentor().instrument(tracer_provider=provider)\nOpenAI().chat.completions.create(model=\"extract-1\", messages=[{\"role\": \"user\", \"content\":\n    \"Hi, I'm Joana Prado (joana.prado@example.com, +55 11 5550-0142). Is my order MG-20481937 lost?\"}])",
      "note": "The demonstration: the lab's JSON-lines exporter, wrapped or not, behind OpenInference, which lesson 1 showed keeps the whole prompt. One message from a customer, with an address, a telephone number and an order."
    }
  ]
}
```

```
ana@lab:~/obs$ python leak.py raw.jsonl && grep -o "joana.prado@example.com" raw.jsonl | wc -l
2
ana@lab:~/obs$ python leak.py clean.jsonl --redact && grep -o "joana.prado@example.com" clean.jsonl | wc -l
0
ana@lab:~/obs$ python tree.py --spans clean.jsonl --attrs | grep "message.content"
                     llm.input_messages.0.message.content = "Hi, I'm Joana Prado ([email], [phone]). Is my order [order] lost?"
                     llm.output_messages.0.message.content = "You can call Marginalia's customer service on 0800 555 0199, every day from 9 am to 6 pm."
```

Without the wrapper, the address is in the file twice: in the prompt as OpenInference recorded it,
`input.value`, and again in `llm.input_messages`. With it, neither. The reply, a sentence about
Marginalia's customer service from extract-1's memory, is untouched because it carries nothing the
patterns match. A real model's reply to that message could have greeted Joana by name and repeated
her address back to her, and the wrapper would have taken the address out of that too.

## Why at the exporter, and not at the start of the span

OpenTelemetry's SDK lets code watch spans start and end through a **span processor**. It would be the
natural place, except that by the time a processor sees a finished span, the span is read-only in the
Python SDK, and at the start, the attributes a library adds during the call are not there yet. The
exporter is the last point inside the process where every attribute exists and nothing has left.
That is why the wrapper builds a new span for each one rather than editing it.

The same idea exists outside the process. **The OpenTelemetry Collector**, which `observability`
lesson 2 puts between services and their backends, has processors for exactly this: rules that
delete or replace attributes, or match their values against patterns, before anything is forwarded.
`observability` lesson 10 does it for logs; for spans it was not run here. It is the right place when several services send spans and each would otherwise
carry its own copy of the rules.

## What a second net costs

Every string attribute of every span goes through four regular expressions, which is microseconds for
a span of this size. The price that matters is **false positives**: a pattern that matches something
harmless removes it from every trace, including the ones somebody needs to debug. The next section
finds one.
