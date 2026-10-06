---
title: Letting a library write the spans
version: 1
---

Writing every span by hand is what `assistant.py` does, and it is not what most teams do first. The
usual first step is an **instrumentation library**: a package that wraps the provider's SDK, so that
every call made through it produces a span without a line of tracing code in the application.
`observability` lesson 3 does the same for web frameworks and database drivers, and says where that
stops being enough; this section looks at what one of these libraries records for a model call.

OpenInference is one of them. It is Arize's set of instrumentors and conventions, and Phoenix, in
lesson 7, reads what it writes. `auto.py` is `one_call.py` with no span in it:

```python
"""The same call with no span written by hand: OpenInference instruments the SDK."""
from openai import OpenAI
from openinference.instrumentation.openai import OpenAIInstrumentor

import telemetry

provider = telemetry.setup("auto.jsonl")
OpenAIInstrumentor().instrument(tracer_provider=provider)

client = OpenAI()
reply = client.chat.completions.create(
    model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
print(reply.choices[0].message.content)
```

`instrument()` replaces the SDK's methods with versions that open a span, call the original, and
fill the span from what went in and what came out.

```
ana@lab:~/obs$ python auto.py
Marginalia gift cards are valid for one year from purchase.
ana@lab:~/obs$ python tree.py --spans auto.jsonl --attrs
trace 2c7a843d776d088f6cef8f657c830b0a   start(ms) took(ms)
      0     605 ms  ChatCompletion
                     llm.system = "openai"
                     input.value = "{\"model\": \"extract-1\", \"messages\": [{\"role\": \"user\", \"content\": \"How long is a gift card valid?\"}]}"
                     input.mime_type = "application/json"
                     output.value = "{\"id\":\"chatcmpl-lab0015\",\"choices\":[{\"finish_reason\":\"stop\",\"index\":0,\"message\":{\"content\":\"Marginalia gift cards are valid for one year from purchase.\",\"role\":\"assistant\"}}],\"created\":1791255600,\"model\":\"extract-1\",\"object\":\"chat.completion\",\"usage\":{\"completion_tokens\":13,\"prompt_tokens\":11,\"total_tokens\":24}}"
                     output.mime_type = "application/json"
                     llm.invocation_parameters = "{\"model\": \"extract-1\"}"
                     llm.input_messages.0.message.role = "user"
                     llm.input_messages.0.message.content = "How long is a gift card valid?"
                     llm.model_name = "extract-1"
                     llm.token_count.total = 24
                     llm.token_count.prompt = 11
                     llm.token_count.completion = 13
                     llm.output_messages.0.message.role = "assistant"
                     llm.output_messages.0.message.content = "Marginalia gift cards are valid for one year from purchase."
                     llm.finish_reason = "stop"
                     openinference.span.kind = "LLM"
```

## What it recorded, and in which names

The span is called `ChatCompletion`, and its attributes are in **OpenInference's own convention**,
not OpenTelemetry's: `llm.model_name` where the previous section had `gen_ai.request.model`,
`llm.token_count.prompt` where it had `gen_ai.usage.input_tokens`, and `openinference.span.kind =
"LLM"`, which Phoenix uses to choose how to draw it. The facts are the same and the names are not,
which is the first thing to settle when choosing a tool: what it writes and what it reads. Lesson 7
comes back to it.

The two conventions are converging. The version of OpenInference in the lab has a setting that makes
it write OpenTelemetry's names instead:

```
ana@lab:~/obs$ rm auto.jsonl; OPENINFERENCE_ENABLE_GENAI_SEMCONV=true python auto.py
Marginalia gift cards are valid for one year from purchase.
ana@lab:~/obs$ python tree.py --spans auto.jsonl --attrs | grep gen_ai
                     gen_ai.operation.name = "chat"
                     gen_ai.provider.name = "openai"
                     gen_ai.request.model = "extract-1"
                     gen_ai.usage.input_tokens = 11
                     gen_ai.usage.output_tokens = 13
                     gen_ai.input.messages = "[{\"role\": \"user\", \"parts\": [{\"type\": \"text\", \"content\": \"How long is a gift card valid?\"}]}]"
                     gen_ai.output.messages = "[{\"role\": \"assistant\", \"parts\": [{\"type\": \"text\", \"content\": \"Marginalia gift cards are valid for one year from purchase.\"}], \"finish_reason\": \"stop\"}]"
                     gen_ai.response.finish_reasons = ["stop"]
                     gen_ai.response.id = "chatcmpl-lab0016"
                     gen_ai.response.model = "extract-1"
```

Same call, and now `gen_ai.request.model` and `gen_ai.usage.input_tokens`, which any tool that reads
the OpenTelemetry convention understands. Expect settings like this to change name and default from
one release to the next while the convention is young; read the span after every upgrade.

## And what it recorded that nobody asked for

Read `input.value` and `llm.input_messages.0.message.content` in the first capture, or
`gen_ai.input.messages` in the second. **The library recorded the whole
prompt, and the whole reply, by default.** Here that is a question about gift cards. In production it
is whatever a customer typed, and lesson 2 shows what customers type: names, e-mail addresses,
telephone numbers, order numbers, and now and then a card number. Every instrumentation library for
models faces the same choice, and most of them default to keeping the text, because the text is what
makes a trace useful when debugging. OpenInference reads environment variables such as
`OPENINFERENCE_HIDE_INPUTS` and `OPENINFERENCE_HIDE_OUTPUTS` to leave it out; OpenTelemetry's own
instrumentation for the OpenAI SDK does the opposite, and leaves the content out unless
`OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` asks for it. That second one was not run here.

Neither default is wrong. What is wrong is not knowing which one is running, and that is easy to
find out: call the model once and read the span, as above, before a single customer's message goes
through it.

## Hand-written, automatic, or both

| | by hand | by a library |
|---|---|---|
| what it costs | a line per attribute, in every place a call is made | one call at start-up |
| what it covers | what you remembered | every call through that SDK, including ones in code you did not write |
| what it knows | your names: the feature, the release, the chunks kept | the request and the response, and nothing about why the call was made |
| what it keeps | what you chose | the library's default, which you have to look up |

They combine. A library's span for each call nests under a hand-written span for the step that made
it, as long as the step's span is current when the call happens, which is what `span()` does. The
assistant writes its own model spans for one reason only: it streams, retries and measures the first
token in its own code, and those are the things lessons 4 and 5 need on the span.
