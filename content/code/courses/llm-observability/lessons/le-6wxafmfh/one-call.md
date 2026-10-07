---
title: A span around one call
version: 2
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
      "code": "\"\"\"one_call.py: one model call, with a span around it, printed to the terminal when it ends.\"\"\"\nfrom openai import OpenAI\nfrom opentelemetry import trace\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor\n\nprovider = TracerProvider()\nprovider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))\ntrace.set_tracer_provider(provider)\ntracer = trace.get_tracer(\"one_call\")\n\n",
      "note": "The SDK's three parts: a provider that makes spans, a processor that hands each finished span on, and an exporter that writes it somewhere. Here, the terminal, one span at a time."
    },
    {
      "code": "client = OpenAI()\nwith tracer.start_as_current_span(\"chat llama3.2:3b\") as span:\n    span.set_attribute(\"gen_ai.operation.name\", \"chat\")\n    span.set_attribute(\"gen_ai.request.model\", \"llama3.2:3b\")\n",
      "note": "The span opens before the request goes out, so its duration includes the wait for the model. Its name and first two attributes say what was asked for, before any answer exists."
    },
    {
      "code": "    reply = client.chat.completions.create(\n        model=\"llama3.2:3b\", temperature=0,\n        messages=[{\"role\": \"user\", \"content\": \"How long is a Marginalia gift card valid?\"}])\n",
      "note": "The call itself. The question names the shop, and nothing else: no documents go with it."
    },
    {
      "code": "    span.set_attribute(\"gen_ai.response.model\", reply.model)\n    span.set_attribute(\"gen_ai.response.finish_reasons\", [reply.choices[0].finish_reason])\n    span.set_attribute(\"gen_ai.usage.input_tokens\", reply.usage.prompt_tokens)\n    span.set_attribute(\"gen_ai.usage.output_tokens\", reply.usage.completion_tokens)\nprint(reply.choices[0].message.content)\n",
      "note": "What came back: which model answered, why it stopped, and the tokens on each side, read from the reply's `usage`. The span closes at the end of the block, and the exporter prints it."
    }
  ]
}
```

```
ana@dev:~/obs$ python one_call.py
{
    "name": "chat llama3.2:3b",
    "context": {
        "trace_id": "0x4180c8f065f602f38fb728f61f5a079f",
        "span_id": "0x9dd954745af919d3",
        "trace_state": "[]"
    },
    "kind": "SpanKind.INTERNAL",
    "parent_id": null,
    "start_time": "2026-10-07T23:47:44.760014Z",
    "end_time": "2026-10-07T23:47:56.454514Z",
    "status": {
        "status_code": "UNSET"
    },
    "attributes": {
        "gen_ai.operation.name": "chat",
        "gen_ai.request.model": "llama3.2:3b",
        "gen_ai.response.model": "llama3.2:3b",
        "gen_ai.response.finish_reasons": [
            "stop"
        ],
        "gen_ai.usage.input_tokens": 36,
        "gen_ai.usage.output_tokens": 75
    },
    "events": [],
    "links": [],
    "resource": {
        "attributes": {
            "telemetry.sdk.language": "python",
            "telemetry.sdk.name": "opentelemetry",
            "telemetry.sdk.version": "1.45.0",
            "service.instance.id": "932c115f-77a5-4a12-962c-e4c90052f169",
            "service.name": "unknown_service:python"
        },
        "schema_url": ""
    }
}
I couldn't find any information on a gift card called "Marginalia." It's possible that it's a lesser-known or regional gift card, or it may be a misspelling or incorrect name.

If you could provide more context or clarify the name of the gift card, I'd be happy to try and help you find the information you're looking for.
```

Everything in that record is something a log line could also have said, apart from two things: the
**trace id and span id**, which let this span be found and joined to others, and the **start and end
times**, which are 11.7 seconds apart. That is the whole of the model call, from the request leaving
to the reply being read, and on this occasion most of it was Ollama loading the model into memory:
it was the first question the server had been asked since it started. The traces in section 07 show
what an ordinary call takes.

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
`gpt-4o` is answered by whatever dated snapshot the alias points at that day, and the reply says
which one. Ollama's names work the same way: `llama3.2:3b` is a tag, and pulling it again on another
day can bring a different file under the same name, which is why `ollama list` shows an id beside
it. Lesson 14 is about the day request and response differ.

## What the span did not catch

Read the reply. The model has never heard of a gift card called Marginalia, says so, and asks for
more context: 75 tokens that a customer could do nothing with. The shop's documents say a card is
valid for two years, but `one_call.py` sent the question with nothing else, and a model knows only
what it learnt in training plus what it is handed. That is why the assistant in section 07 hands it
the documents. This time the model admitted it; asked about something closer to what it learnt, it
would just as readily have given a confident number, and a wrong one.

**The span is perfect and the answer is useless**, and nothing in the span can tell the two apart:
the status is `UNSET`, the finish reason is `stop`, the token counts are plausible.

That is the line this course keeps drawing. A trace says **what happened**: which steps ran, in what
order, how long each took, what each cost. Whether the answer was any good is a different question,
with different instruments, and lessons 8 to 13 build them.
