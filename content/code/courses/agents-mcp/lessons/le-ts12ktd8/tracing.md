---
title: Traces that stay here
version: 2
---

The SDK records a **trace** for every run: a tree of spans, one for each model call, tool call, handoff and guardrail, with timings. By default it sends them to OpenAI's servers, where the platform shows them in a dashboard. The endpoint is written into the library (`https://api.openai.com/v1/traces/ingest`), and a deployment that must not send conversation data to that service has to turn the export off or replace it. `oa_run.py` turned it off; `oa_trace.py` replaces it with a processor that prints each span on this machine.

```python
"""The SDK's tracing, kept on this machine: a processor that prints every span as it ends."""
import sys
from datetime import datetime

from agents import Agent, Runner, set_trace_processors
from agents.tracing import TracingProcessor

from oa_tools import get_order, search_help



class PrintSpans(TracingProcessor):
    def on_trace_start(self, trace):
        print(f"trace {trace.name!r}")

    def on_span_end(self, span):
        data = span.span_data.export()
        label = data.get("name") or data.get("model") or ""
        took = datetime.fromisoformat(span.ended_at) - datetime.fromisoformat(span.started_at)
        ms = int(took.total_seconds() * 1000)
        print(f"  {data['type']:10} {label:22} {ms} ms")

    def on_trace_end(self, trace): pass
    def on_span_start(self, span): pass
    def shutdown(self): pass
    def force_flush(self): pass


set_trace_processors([PrintSpans()])  # replaces the default exporter, which sends traces to OpenAI
agent = Agent(name="Marginalia support", model="llama3.2:3b", tools=[get_order, search_help],
              instructions="You answer Marginalia's customers with the OpenAI Agents SDK. Use the tools; never guess.")
Runner.run_sync(agent, sys.argv[1])
```

`set_trace_processors([...])` replaces the default processors, the exporter included; `add_trace_processor` would have added one beside it, and the spans would still have been sent.

```
ana@lab:~/agents$ python oa_trace.py "Where is my order M-1043?"
trace 'Agent workflow'
  response                          2056 ms
  function   get_order              1 ms
  custom     turn                   2061 ms
  response                          9375 ms
  custom     turn                   9377 ms
  agent      Marginalia support     11440 ms
  custom     task                   11440 ms
```

The same run as section 03, as the SDK sees it. Each **turn** holds a **response** span (the model call through the Responses API, which carries no model name to print) and, when the model asked for one, a **function** span for the tool. The **agent** span covers the whole run, inside an outer task. The numbers tell the same story as lesson 7's trace: `get_order` took 1 ms, the first model call 2056 ms, and the second 9375 ms, because it writes the answer, the longest piece of writing in the run.

Lesson 7 wrote its own trace in about fifteen lines and decided every field. Here the structure is the SDK's, and richer (nested spans, a standard shape other tools understand), and the decision left to you is where it goes. That decision is not cosmetic: a span holds the model's input and output, which means customers' messages and tool results. **Sending traces to a third party is sending them that data.** Keep them where your other personal data lives, or decide deliberately, and in writing, that they may leave.
