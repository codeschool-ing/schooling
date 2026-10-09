---
title: Adding the names it reads
version: 2
---

Langfuse documents a set of attributes it reads on top of OpenTelemetry's: `langfuse.observation.type`
to say what a span is, `langfuse.trace.input` and `output`, `langfuse.user.id` and
`langfuse.session.id`, and the plain `user.id` and `session.id` as well. The assistant could write
them itself. It is better not to: they are one tool's names, and the day the spans go somewhere else
they are noise in somebody else's metadata.

So they are added **on the way out**, by a span processor that the replay loads only when asked.
OpenTelemetry calls a processor's `on_start` as each span begins, with the span still writable and the
attributes it was created with already on it:

```python
"""lf_names.py: a span processor that adds, as each span starts, the names Langfuse reads."""
from opentelemetry.sdk.trace import SpanProcessor


class LangfuseNames(SpanProcessor):
    def on_start(self, span, parent_context=None):
        if span.name == "ask":
            a = span.attributes
            span.set_attribute("langfuse.observation.type", "span")   # the root is not a model call
            span.set_attribute("user.id", a["user.hash"])               # the pseudonym, under the name it reads
            span.set_attribute("langfuse.trace.input", a["app.question"])
```

`replay.py` takes `--processor MODULE:CLASS` and adds each to the provider before the exporters. The
replay of Saturday, with it:

```
ana@dev:~/obs$ export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$LANGFUSE_BASE_URL/api/public/otel/v1/traces OTEL_EXPORTER_OTLP_TRACES_HEADERS="Authorization=Basic $(printf %s $LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY | base64 -w0)"; python replay.py --from 2026-10-03 --to 2026-10-04 --processor lf_names:LangfuseNames
replayed 31 requests from data/traffic.jsonl: 36 asked, 0 failed, 12 feedback events
ana@dev:~/obs$ python lf.py traces 2026-10-03 1
2026-10-03T09:25:27 f0320995 ask user 759c1b8e0d00460b session s222 cost 0 input 'How long is the statutory right of withdrawal?'
```

The user is the pseudonym, under a name Langfuse reads, and the trace has its question as input. And
the root now says it is a plain span, so nothing that counts generations counts it. Nothing in
`assistant.py` changed, and the file the same spans went to still has none of the `langfuse.*`
names.

## Why the reply is not there

`on_start` sees what the span was created with, and the reply is set on the root at the end of the
request. To copy it as well, the copying has to happen when the span ends, and by then the Python SDK
has made the span read-only; lesson 2 met the same wall and rebuilt the span in an exporter. The trade
here went the other way: the question is enough to find a trace on a screen, and the reply is one click
away, on the `app.reply` attribute that Langfuse keeps as metadata.

The general point is the one lesson 1 made about OpenInference. **Every tool has a list of names it
reads.** Find out what they are before choosing what to write, and keep the tool's own names in one
small adapter, here eleven lines, rather than spread through the application.
