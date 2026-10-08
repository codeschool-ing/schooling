---
title: Arize Phoenix
version: 2
---

Arize is a company with two products for this. **Arize AX** is its hosted platform, for monitoring and
evaluating models in production, machine learning ones as well as language models. **Phoenix** is its
open-source tracer and evaluation tool, built on OpenTelemetry and on OpenInference, the convention
lesson 1 met. AX is a hosted service and is not run here. Phoenix is a Python package with no other
service behind it, so it installs into the course's environment like any library:

```sh
pip install arize-phoenix==20.18.0
```

```
ana@dev:~/obs$ du -sh ~/llmobs
1.7G	/home/ana/llmobs
ana@dev:~/obs$ pip list 2>/dev/null | grep -E "^opentelemetry-sdk "
opentelemetry-sdk                        1.45.1
```

The environment is now 1.7 GB, most of it Phoenix and what it brings: a web server, a database
layer and pandas among them. pip also moved the OpenTelemetry SDK from 1.45.0, the version lesson 1
pinned, to 1.45.1, because one of Phoenix's own dependencies asks for that release. It is a patch, and
nothing this course reads changes with it.

Then start it in the background, with two settings that are not its defaults:

```sh
PHOENIX_HOST=127.0.0.1 PHOENIX_TELEMETRY_ENABLED=false phoenix serve > ~/phoenix.log 2>&1 &
```

**Left to itself, Phoenix listens on every network interface**, `0.0.0.0`, so anybody on the same
network as your computer can open it, traces and all. `PHOENIX_HOST` keeps it to your own machine.
And its screens report how they are used to two analytics services, FullStory and Scarf, unless
`PHOENIX_TELEMETRY_ENABLED` is false. Neither default is unusual for a tool meant to be shared by a
team; both are worth knowing about before customers' questions go into it. It keeps its data in a
SQLite file under `~/.phoenix`, and stops when you kill it, `kill %1` in the same terminal.

```
ana@dev:~/obs$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:6006/
200
ana@dev:~/obs$ curl -s -o /dev/null -w "%{http_code}\n" http://$(hostname -I | cut -d" " -f1):6006/
000
```

The first address is your own machine, and Phoenix answers. The second is the same computer's
address on its network, the one a colleague's browser would use, and nothing answers there: `000` is
`curl` saying it could not connect. That is `PHOENIX_HOST` doing its job.

It receives OTLP on port 6006, so the assistant needs, again, only an environment variable. The replay
of Sunday, sent to it:

```
ana@dev:~/obs$ OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://127.0.0.1:6006/v1/traces python replay.py --from 2026-10-04 --to 2026-10-05
replayed 32 requests from data/traffic.jsonl: 34 asked, 0 failed, 7 feedback events
```

Phoenix has a Python client, and `px_spans.py` reads the spans back from it as a table, grouped by
name, the way its screens group them:

```python
"""px_spans.py: the spans Phoenix holds, read back through its client, as a table per span name."""
from phoenix.client import Client

spans = Client(base_url="http://127.0.0.1:6006").spans.get_spans_dataframe(project_identifier="default", limit=5000)
print(len(spans), "spans;", spans["context.trace_id"].nunique(), "traces")
print(spans["span_kind"].value_counts().to_string())
spans["ms"] = (spans["end_time"] - spans["start_time"]).dt.total_seconds() * 1000
table = spans.groupby("name").agg(spans=("name", "size"), kind=("span_kind", "first"), median_ms=("ms", "median"),
                                  prompt_tokens=("attributes.llm.token_count.prompt", "sum"))
print(table.round(0).to_string())
```

```
ana@dev:~/obs$ python px_spans.py
182 spans; 34 traces
span_kind
UNKNOWN      90
LLM          60
EMBEDDING    32
                  spans       kind  median_ms  prompt_tokens
name                                                        
ask                  34        LLM     2857.0            0.0
chat llama3.2:3b     26        LLM     3058.0         4379.0
check_citations      32    UNKNOWN        0.0            0.0
embed                32  EMBEDDING      146.0          478.0
generate             26    UNKNOWN     3059.0            0.0
search               32    UNKNOWN        0.0            0.0
```

## What it made of the spans

Phoenix sorts spans by **kind**, OpenInference's `openinference.span.kind`: `LLM`, `EMBEDDING`,
`RETRIEVER`, `TOOL`, `CHAIN` and a few others, and draws each kind differently. The assistant writes
no OpenInference names at all, and Phoenix read its `gen_ai.*` attributes and translated them: the
chat spans became `LLM` with their prompt tokens counted, the embeddings `EMBEDDING`. The convergence
lesson 1 saw from OpenInference's side is happening from Phoenix's too.

And the root again. **`ask` is an `LLM` span with no tokens**, for the same reason Langfuse made it a
generation: it carries `gen_ai.request.model`. Two tools, built by two companies, made the same
reading of the same attribute. That is good evidence that the attribute is in the wrong place, and the
fix belongs in `assistant.py` rather than in an adapter per tool: record the release's model as
`app.model` on the root, and keep `gen_ai.*` for spans that are model calls. The course leaves
`assistant.py` as it is so that every lesson's transcript still matches, and the drill asks what the
change would affect.

The other thing to read in the table: **`search` is `UNKNOWN`**. Phoenix has a `RETRIEVER` kind made
for it, which shows the documents retrieved and their scores in its own panel; the assistant's search
span does not say it is one. Adding `openinference.span.kind = RETRIEVER`, and the chunk ids as
OpenInference's `retrieval.documents`, is an adapter of the same shape as lesson 6's.

Notice also the prompt tokens of `embed`: 478. Phoenix counts an embedding's input as prompt tokens,
which is fair, and a total of prompt tokens across all kinds would then mix two prices.
