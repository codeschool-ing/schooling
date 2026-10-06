---
title: A span around one call
version: 1
---

A **span** is the record of one operation: a name, when it started and ended, whether it failed, and
attributes, which are key-value pairs saying what it was about. A **trace** is the spans of one piece
of work, held together by the trace id they share and each pointing at its parent. `observability`
lesson 2 builds them in general, with OpenTelemetry's SDK; this course uses the same SDK and asks
what is particular about a span whose operation is a call to a model.

Start with the smallest case: one call, one span, written to the terminal as it ends.

```schooling-example
{
  "language": "python",
  "file": "one_call.py",
  "parts": [
    {
      "code": "\"\"\"One model call, with a span around it, printed to the terminal when it ends.\"\"\"\nfrom openai import OpenAI\nfrom opentelemetry import trace\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\n\nprovider = TracerProvider()\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))\ntrace.set_tracer_provider(provider)\ntracer = trace.get_tracer(\"one_call\")",
      "note": "The SDK's three parts: a provider that makes spans, a processor that hands each finished span on, and an exporter that writes it somewhere. Here, the terminal, one span at a time."
    },
    {
      "code": "client = OpenAI()\nwith tracer.start_as_current_span(\"chat extract-1\") as span:\n    span.set_attribute(\"gen_ai.operation.name\", \"chat\")\n    span.set_attribute(\"gen_ai.request.model\", \"extract-1\")",
      "note": "The span opens before the request goes out, so its duration includes the wait for the provider. Its name and first two attributes say what was asked for, before any answer exists."
    },
    {
      "code": "    reply = client.chat.completions.create(\n        model=\"extract-1\", messages=[{\"role\": \"user\", \"content\": \"How long is a gift card valid?\"}])",
      "note": "The call itself, unchanged."
    },
    {
      "code": "    span.set_attribute(\"gen_ai.response.model\", reply.model)\n    span.set_attribute(\"gen_ai.response.finish_reasons\", [reply.choices[0].finish_reason])\n    span.set_attribute(\"gen_ai.usage.input_tokens\", reply.usage.prompt_tokens)\n    span.set_attribute(\"gen_ai.usage.output_tokens\", reply.usage.completion_tokens)\nprint(reply.choices[0].message.content)",
      "note": "What came back: which model answered, why it stopped, and the tokens on each side, read from the reply's `usage`. The span closes at the end of the block."
    }
  ]
}
```

```
ana@lab:~/obs$ python one_call.py
{
    "name": "chat extract-1",
    "context": {
        "trace_id": "0xd4a8903817f935061c7255069d52f5c8",
        "span_id": "0x15f2ef0a0e59a80f",
        "trace_state": "[]"
    },
    "kind": "SpanKind.INTERNAL",
    "parent_id": null,
    "start_time": "2026-10-06T06:47:23.748671Z",
    "end_time": "2026-10-06T06:47:24.383897Z",
    "status": {
        "status_code": "UNSET"
    },
    "attributes": {
        "gen_ai.operation.name": "chat",
        "gen_ai.request.model": "extract-1",
        "gen_ai.response.model": "extract-1",
        "gen_ai.response.finish_reasons": [
            "stop"
        ],
        "gen_ai.usage.input_tokens": 11,
        "gen_ai.usage.output_tokens": 13
    },
    "events": [],
    "links": [],
    "resource": {
        "attributes": {
            "telemetry.sdk.language": "python",
            "telemetry.sdk.name": "opentelemetry",
            "telemetry.sdk.version": "1.45.0",
            "service.instance.id": "66df69dd-62b0-4bf2-8ac7-a4f835754534",
            "service.name": "unknown_service:python"
        },
        "schema_url": ""
    }
}
Marginalia gift cards are valid for one year from purchase.
```

Everything in that record is something a log line could also have said, apart from two things: the
**trace id and span id**, which let this span be found and joined to others, and the **start and end
times**, which are 635 ms apart. That is the whole of the model call, from the request leaving to
the reply being read.

## Names somebody else chose

The attribute names are not this course's. They are OpenTelemetry's **semantic conventions for
generative AI**, the `gen_ai.*` namespace: `gen_ai.operation.name` says what kind of call it was
(`chat`, `embeddings`, `execute_tool`), `gen_ai.request.model` what was asked for,
`gen_ai.response.model` what answered, and `gen_ai.usage.input_tokens` and `output_tokens` what it
cost in tokens. The convention also says how to name the span: the operation, a space and the model.

Using somebody else's names is the point. A tracing tool that knows the convention can find the
token counts in any program that follows it, and lessons 6 and 7 send these same spans to two tools
that were never told anything about Marginalia. The convention was still marked as in development
when this course was written, and one name had already changed: what is now
`gen_ai.provider.name` used to be `gen_ai.system`. Pin the version of whatever writes them, and
expect a rename or two when you upgrade.

Request and response model are two attributes for a reason. A request for an alias such as
`gpt-4o` is answered by whatever dated snapshot the alias points at that day,
and the reply says which one. Lesson 14 is about the day those two differ.

## What the span did not catch

Read the reply: *Marginalia gift cards are valid for one year from purchase.* That is wrong; the
documents say two. `one_call.py` sent the question with no sources, so extract-1 answered from what
it "learnt in training", which `rag` lesson 1 showed to be last year's rules. **The span is perfect
and the answer is wrong**, and nothing in the span can tell the two apart: the status is `UNSET`, the
finish reason is `stop`, the token counts are plausible.

That is the line this course keeps drawing. A trace says **what happened**: which steps ran, in what
order, how long each took, what each cost. Whether the answer was any good is a different question,
with different instruments, and lessons 8 to 13 build them.
