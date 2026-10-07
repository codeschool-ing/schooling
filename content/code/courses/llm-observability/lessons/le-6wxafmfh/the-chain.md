---
title: A chain of calls
version: 2
---

One call is rarely the whole of an answer. Marginalia's assistant does four things for every
question: it turns the question into numbers, searches the index with them, asks the model to
answer from what it found, and checks the citations in the reply. Two of those are calls to a
model, one is arithmetic on the index, and one is plain Python. A trace of the request gives each
its own span and nests them under one root, so that a slow or a wrong answer can be taken apart.

Three programs do it, and all three go in `~/obs`. `telemetry.py` decides where spans go and opens
every one of them:

```schooling-example
{
  "language": "python",
  "file": "telemetry.py",
  "parts": [
    {
      "code": "\"\"\"telemetry.py: where the assistant's spans go, and the clock they are stamped with.\n\n    import telemetry\n    telemetry.setup(\"spans.jsonl\")          # once, at start-up\n    with telemetry.span(\"search\") as s:     # every step\n        s.set_attribute(\"search.k\", 3)\n\nEvery span is written to a JSON-lines file, one span per line, as it ends. If\nOTEL_EXPORTER_OTLP_TRACES_ENDPOINT is set, the same spans also go there over\nOTLP/HTTP, which is how they reach Phoenix and Langfuse in lessons 6 and 7.\n\"\"\"\nimport contextlib\nimport contextvars\nimport json\nimport os\nimport time\n\nfrom opentelemetry import trace\nfrom opentelemetry.sdk.resources import Resource\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import (BatchSpanProcessor, SimpleSpanProcessor, SpanExporter,\n                                            SpanExportResult)\nfrom opentelemetry.trace import Status, StatusCode\n\n",
      "note": "What the file is for, and how the assistant uses it: `setup()` once, then `span()` around every step."
    },
    {
      "code": "# replay.py plays a week of traffic in under an hour. It sets this offset so\n# that each request's spans carry the moment the traffic file gives it; the\n# durations inside them are measured, never shifted.\nOFFSET_NS = contextvars.ContextVar(\"offset_ns\", default=0)\n\n\ndef now_ns():\n    return time.time_ns() + OFFSET_NS.get()\n\n\n",
      "note": "The clock. Normally the offset is zero and a span carries the moment it ran. Lesson 3's `replay.py` sets it, per request, so that a week replayed today carries the week's dates; it moves the start and the end together and never changes a duration."
    },
    {
      "code": "class JsonlExporter(SpanExporter):\n    \"\"\"One line per finished span: ids, name, times in nanoseconds, status, attributes, events.\"\"\"\n\n    def __init__(self, path):\n        self.path = path\n\n    def export(self, spans):\n        with open(self.path, \"a\") as f:\n            for s in spans:\n                f.write(json.dumps({\n                    \"trace\": f\"{s.context.trace_id:032x}\", \"span\": f\"{s.context.span_id:016x}\",\n                    \"parent\": f\"{s.parent.span_id:016x}\" if s.parent else None,\n                    \"name\": s.name, \"start\": s.start_time, \"end\": s.end_time,\n                    \"status\": s.status.status_code.name, \"error\": s.status.description,\n                    \"attributes\": dict(s.attributes),\n                    \"events\": [{\"name\": e.name, \"at\": e.timestamp, \"attributes\": dict(e.attributes)}\n                               for e in s.events]}, ensure_ascii=False) + \"\\n\")\n        return SpanExportResult.SUCCESS\n\n\n",
      "note": "Where a finished span goes: one line of JSON in a file, with its trace and span ids, its parent, its times in nanoseconds, its status and its attributes. `tree.py` reads this file."
    },
    {
      "code": "def setup(path=\"spans.jsonl\", service=\"assistant\", processors=()):\n    provider = TracerProvider(resource=Resource.create({\"service.name\": service}))\n    for p in processors:  # lesson 2's redaction goes here, before any exporter sees a span\n        provider.add_span_processor(p)\n    provider.add_span_processor(SimpleSpanProcessor(JsonlExporter(path)))\n    if os.environ.get(\"OTEL_EXPORTER_OTLP_TRACES_ENDPOINT\"):\n        from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter\n        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))\n    trace.set_tracer_provider(provider)\n    return provider\n\n\ntracer = trace.get_tracer(\"marginalia.assistant\")\n\n\n",
      "note": "The SDK's three parts: a provider that makes spans, a processor that hands each finished span on, and an exporter that writes it. The file always; an OTLP endpoint as well when one is set, which is how lessons 6 and 7 send the same spans to a tool with a screen."
    },
    {
      "code": "@contextlib.contextmanager\ndef span(name, **attributes):\n    \"\"\"A span stamped with the replay's clock, marked as an error if the block raises.\"\"\"\n    s = tracer.start_span(name, attributes=attributes or None, start_time=now_ns())\n    with trace.use_span(s, end_on_exit=False):\n        try:\n            yield s\n        except BaseException as e:\n            s.set_status(Status(StatusCode.ERROR, f\"{type(e).__name__}: {e}\"))\n            s.record_exception(e, timestamp=now_ns())\n            raise\n        finally:\n            s.end(end_time=now_ns())\n\n\ndef event(name, **attributes):\n    trace.get_current_span().add_event(name, attributes, timestamp=now_ns())\n",
      "note": "`span()` is the one way the assistant opens a span. It stamps the start and the end with the clock above, makes the new span current so that any span opened inside it becomes its child, and if the block raises, marks the span as an error and records the exception before letting it through."
    }
  ]
}
```

`assistant.py` is the assistant, with a span around every step:

```schooling-example
{
  "language": "python",
  "file": "assistant.py",
  "parts": [
    {
      "code": "\"\"\"assistant.py: Marginalia's help assistant, with a span on every step.\n\n    python assistant.py [--user ID] [--feature help|order|summary] \"QUESTION\"\n\nIt searches data/index.json for the chunks closest to the question, hands the\nones that clear the release's floor to the model as numbered sources, and\nchecks the citations in the reply. What a person typed is redacted before it\nis recorded (lesson 2), and the reply is streamed, with the retries in this\nfile rather than inside the SDK, so each attempt is a span of its own (lesson 4).\n\"\"\"\nimport json\nimport os\nimport re\nimport time\nfrom datetime import datetime\n\nimport numpy as np\nfrom openai import APIError, OpenAI\n\nimport redact\nimport telemetry\nfrom telemetry import event, span\n\nRELEASES = json.load(open(\"releases.json\"))\nINDEX = json.load(open(\"data/index.json\"))\nCHUNKS = [c for c in INDEX[\"chunks\"] if c[\"status\"] == \"current\" and c[\"audience\"] == \"public\"]\nVECTORS = np.array([c[\"embedding\"] for c in CHUNKS])\nVECTORS /= np.linalg.norm(VECTORS, axis=1, keepdims=True)\nREFUSAL = \"I could not find that in our documents.\"\nSYSTEM = \"\"\"You answer questions from Marginalia's customers, using only the numbered sources.\nCite every sentence with the number of the source it comes from, like [1].\nIf the sources do not answer the question, reply: \"I could not find that in our documents.\"\nIf two sources disagree, prefer the one updated most recently, and say so.\"\"\"\nATTEMPTS = 3\n\n",
      "note": "The settings, the index and the instructions, read once at start-up. The search only ever sees chunks that are current and public: the superseded policy and the finance team's document are dropped here, before any question arrives."
    },
    {
      "code": "client = OpenAI(max_retries=0, timeout=60)\n\n\nclass IncompleteReply(Exception):\n    \"\"\"The stream ended without a finish reason: the connection dropped mid-answer.\"\"\"\n\n\n",
      "note": "The SDK's own retries are turned off, `max_retries=0`, because the assistant retries in its own code below, where each attempt can be a span. Lesson 4 shows what an SDK retry looks like in a trace: nothing."
    },
    {
      "code": "def release_at(at):\n    \"\"\"The release in force at AT, an ISO time: the latest whose `from` is not after it.\"\"\"\n    live = [(r[\"from\"], name) for name, r in RELEASES.items() if r[\"from\"] <= at]\n    name = max(live)[1]\n    return name, RELEASES[name]\n\n\n",
      "note": "Which release was in force at a given moment. Today, that is the latest one; when lesson 3 replays a week, it is whichever applied to each request's own time."
    },
    {
      "code": "def retrieve(question, cfg):\n    with span(\"embed\", **{\"gen_ai.operation.name\": \"embeddings\", \"gen_ai.request.model\": INDEX[\"embedder\"]}) as s:\n        r = client.embeddings.create(model=INDEX[\"embedder\"], input=[question])\n        s.set_attribute(\"gen_ai.usage.input_tokens\", r.usage.prompt_tokens)\n    with span(\"search\", **{\"app.search.k\": cfg[\"k\"], \"app.search.floor\": cfg[\"floor\"]}) as s:\n        q = np.array(r.data[0].embedding)\n        scores = VECTORS @ (q / np.linalg.norm(q))\n        best = np.argsort(-scores)[:cfg[\"k\"]]\n        kept = [(CHUNKS[i], float(scores[i])) for i in best if scores[i] >= cfg[\"floor\"]]\n        s.set_attribute(\"app.search.returned\", len(best))\n        s.set_attribute(\"app.search.kept\", len(kept))\n        s.set_attribute(\"app.search.top_score\", round(float(scores[best[0]]), 3))\n        s.set_attribute(\"app.search.chunks\", [c[\"id\"] for c, _ in kept])\n    return kept\n\n\n",
      "note": "Retrieval is two spans, because it is two operations with different ways of going wrong. The embedding is a call to a model. The search is arithmetic on the index: the similarity of the question to every chunk, the best `k`, and of those, the ones that clear the floor. The span records how many came back, how many were kept, the best score, and which chunks."
    },
    {
      "code": "def chat(model, messages, max_tokens):\n    \"\"\"One attempt: a streamed completion, with the time to its first token.\"\"\"\n    with span(f\"chat {model}\", **{\"gen_ai.operation.name\": \"chat\", \"gen_ai.provider.name\": \"ollama\",\n                                  \"gen_ai.request.model\": model, \"gen_ai.request.max_tokens\": max_tokens,\n                                  \"gen_ai.request.temperature\": 0}) as s:\n        started, first, parts, finish, usage = time.monotonic(), None, [], None, None\n        stream = client.chat.completions.create(model=model, max_tokens=max_tokens, messages=messages,\n                                                temperature=0, stream=True,\n                                                stream_options={\"include_usage\": True})\n        for chunk in stream:\n            if chunk.usage:\n                usage = chunk.usage\n            for c in chunk.choices:\n                if c.delta.content:\n                    if first is None:\n                        first = time.monotonic()\n                        event(\"gen_ai.first_token\")\n                    parts.append(c.delta.content)\n                finish = c.finish_reason or finish\n        if first is not None:\n            s.set_attribute(\"app.time_to_first_token_ms\", round((first - started) * 1000))\n        if usage:\n            s.set_attribute(\"gen_ai.usage.input_tokens\", usage.prompt_tokens)\n            s.set_attribute(\"gen_ai.usage.output_tokens\", usage.completion_tokens)\n        if finish is None:\n            s.set_attribute(\"app.partial_pieces\", len(parts))\n            raise IncompleteReply(f\"stream ended after {len(parts)} pieces with no finish reason\")\n        s.set_attribute(\"gen_ai.response.model\", chunk.model)\n        s.set_attribute(\"gen_ai.response.finish_reasons\", [finish])\n        return \"\".join(parts)\n\n\n",
      "note": "One attempt at the model. The request is streamed, as it is to a customer's screen, so the span can record when the first piece of text arrived as well as when the last did. Lesson 4 needs both. Temperature 0 makes the model pick its most likely word every time, so the same question gets the same answer far more often than not."
    },
    {
      "code": "def generate(messages, model, max_tokens=300):\n    \"\"\"chat(), tried up to ATTEMPTS times on a provider error, one span per attempt.\"\"\"\n    with span(\"generate\") as s:\n        for attempt in range(1, ATTEMPTS + 1):\n            s.set_attribute(\"app.attempts\", attempt)\n            try:\n                return chat(model, messages, max_tokens)\n            except (APIError, IncompleteReply):\n                if attempt == ATTEMPTS:\n                    raise\n                time.sleep(0.5 * 2 ** (attempt - 1))\n\n\n",
      "note": "Up to three attempts, a span each, all inside one `generate` span that records how many it took."
    },
    {
      "code": "def ask(question, user=\"anonymous\", session=None, feature=\"help\", at=None):\n    at = at or datetime.now().isoformat(timespec=\"seconds\")\n    release, cfg = release_at(at)\n    with span(\"ask\", **{\"app.feature\": feature, \"app.release\": release, \"gen_ai.request.model\": cfg[\"model\"],\n                        \"user.hash\": redact.pseudonym(user), \"session.id\": session or \"\",\n                        \"app.question\": redact.redact(question)}) as root:\n        if feature == \"summary\":\n            reply = generate([{\"role\": \"user\", \"content\": question}], cfg[\"model\"], max_tokens=120)\n            outcome, sources = \"summarised\", []\n        else:\n            sources = retrieve(question, cfg)\n            if not sources:\n                reply, outcome = REFUSAL, \"refused\"\n            else:\n                numbered = \"\\n\\n\".join(f\"[{n}] {c['doc']} (updated {c['updated']})\\n{c['text']}\"\n                                       for n, (c, _) in enumerate(sources, 1))\n                reply = generate([{\"role\": \"system\", \"content\": SYSTEM},\n                                  {\"role\": \"user\", \"content\": f\"{numbered}\\n\\nQuestion: {question}\"}],\n                                 cfg[\"model\"])\n                outcome = \"refused\" if REFUSAL in reply else \"answered\"\n            with span(\"check_citations\") as c:\n                cited = [int(n) for n in re.findall(r\"\\[(\\d+)\\]\", reply)]\n                c.set_attribute(\"app.citations.count\", len(cited))\n                c.set_attribute(\"app.citations.dangling\", sum(1 for n in cited if not 0 < n <= len(sources)))\n        root.set_attribute(\"app.outcome\", outcome)\n        root.set_attribute(\"app.reply\", redact.redact(reply))\n        trace_id = f\"{root.get_span_context().trace_id:032x}\"\n    return reply, sources, trace_id\n\n\n",
      "note": "The root span carries what the whole request was: the feature, the release, the model, who asked (as a keyed hash, from `redact.py`) and the question. Everything else opens inside it and becomes its child, without being told. A question nothing in the index answers well enough gets the refusal without the model being called at all."
    },
    {
      "code": "if __name__ == \"__main__\":\n    import argparse\n    p = argparse.ArgumentParser()\n    p.add_argument(\"question\")\n    p.add_argument(\"--user\", default=\"anonymous\")\n    p.add_argument(\"--feature\", default=\"help\", choices=[\"help\", \"order\", \"summary\"])\n    a = p.parse_args()\n    telemetry.setup(os.environ.get(\"SPANS\", \"spans.jsonl\"))\n    reply, sources, trace_id = ask(a.question, user=a.user, feature=a.feature)\n    print(reply)\n    print(f\"trace {trace_id}\")\n",
      "note": "From the command line: one question, the reply, and the trace id of the request that produced it."
    }
  ]
}
```

## One question

```
ana@dev:~/obs$ python assistant.py "Who pays for the return postage?"
According to [1], the customer pays for the return postage.
trace 5ea30205e6a9ef29c4b98b45d1595ab9
```

An answer, a citation and a trace id. Nothing on the screen says how long it took, which documents
it read, or what it cost. `tree.py` reads the spans the assistant wrote to `spans.jsonl` and draws
them as the tree they are:

```python
"""tree.py: one trace from spans.jsonl, drawn as the tree it is.

    python tree.py [TRACE_ID] [--spans FILE] [--attrs]

With no TRACE_ID, the last trace in the file. Each line is a span: when it
started, counted from the start of the trace, how long it took, and its name,
indented under its parent. --attrs adds each span's attributes.
"""
import argparse
import json

p = argparse.ArgumentParser()
p.add_argument("trace", nargs="?")
p.add_argument("--spans", default="spans.jsonl")
p.add_argument("--attrs", action="store_true")
a = p.parse_args()

spans = [json.loads(line) for line in open(a.spans)]
trace = a.trace or spans[-1]["trace"]
mine = [s for s in spans if s["trace"].startswith(trace)]
if not mine:
    raise SystemExit(f"no trace {trace} in {a.spans}")
t0 = min(s["start"] for s in mine)
children = {}
for s in mine:
    children.setdefault(s["parent"], []).append(s)
ids = {s["span"] for s in mine}


def show(s, depth):
    ms = lambda ns: f"{ns / 1e6:,.0f}"
    flag = "  ERROR " + (s["error"] or "") if s["status"] == "ERROR" else ""
    print(f"{ms(s['start'] - t0):>7} {ms(s['end'] - s['start']):>7} ms  {'  ' * depth}{s['name']}{flag}")
    if a.attrs:
        for k, v in s["attributes"].items():
            print(f"{'':19}{'  ' * depth}  {k} = {json.dumps(v, ensure_ascii=False)}")
    for c in sorted(children.get(s["span"], []), key=lambda c: c["start"]):
        show(c, depth + 1)


print(f"trace {mine[0]['trace']}   start(ms) took(ms)")
for root in sorted((s for s in mine if s["parent"] not in ids), key=lambda s: s["start"]):
    show(root, 0)
```

Each line is a span, indented under its parent, with when it started, counted from the start of the
trace, and how long it took. Lessons 6 and 7 replace it with tools that draw the same thing on a
screen.

```
ana@dev:~/obs$ python tree.py
trace 5ea30205e6a9ef29c4b98b45d1595ab9   start(ms) took(ms)
      0   3,021 ms  ask
      0      25 ms    embed
     26       4 ms    search
     31   2,990 ms    generate
     31   2,990 ms      chat llama3.2:3b
  3,021       0 ms    check_citations
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The trace of one answered question as bars on a time axis from 0 to 3,200 ms. ask spans the whole 3,021 ms. Under it, embed takes 25 ms, search 4 ms, generate 2,990 ms, and check_citations under a millisecond at the end. Inside generate, one chat llama3.2:3b span of the same length, whose first token arrived 1,663 ms into the call.\"><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ask</text><rect x=\"170.0\" y=\"22\" width=\"490.91\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"178.0\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3,021 ms</text><text x=\"34\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">embed</text><rect x=\"170.0\" y=\"52\" width=\"4.06\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"180.06\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25 ms</text><text x=\"34\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">search</text><rect x=\"174.22\" y=\"82\" width=\"2\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"182.22\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 ms</text><text x=\"34\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">generate</text><rect x=\"175.04\" y=\"112\" width=\"485.88\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"183.04\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,990 ms</text><text x=\"48\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">chat llama3.2:3b</text><rect x=\"175.04\" y=\"142\" width=\"485.88\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"183.04\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,990 ms</text><text x=\"34\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check_citations</text><rect x=\"660.91\" y=\"172\" width=\"2\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"668.91\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;1 ms</text><path d=\"M445.28 163 L445.28 169\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"449.28\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">first token, 1,663 ms into the call</text><path d=\"M170 208 L690 208\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170.0 208 L170.0 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"170.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M332.5 208 L332.5 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"332.5\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,000</text><path d=\"M495.0 208 L495.0 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"495.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,000</text><path d=\"M657.5 208 L657.5 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"657.5\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3,000</text><text x=\"430\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milliseconds since the trace started</text></svg>", "caption": "Ninety-nine hundredths of the time is one span, and more than half of that is the wait for the first token."}
```

The shape says three things at a glance.

**The spans add up.** `ask` took 3,021 ms, and its children took 25, 4, 2,990 and under 1, one after
the other. Nothing ran in parallel and nothing is missing: a gap between two children would be time
the code spent somewhere that has no span, which is the first thing to look for in a trace that does
not add up.

**One span is nearly all of it.** The model call took 2,990 of the 3,021 ms. Making the search twice
as fast would save 2 ms; making the answer shorter, or the prompt, would save hundreds. A trace is
how that argument is had with numbers instead of opinions, and lesson 4 has it properly.

**`generate` and `chat llama3.2:3b` are the same length** because the call succeeded at the first
attempt. If the model had refused it, `generate` would have had two or three `chat` children, one
per attempt, and the time between them. That is why the retries are in the assistant's code and not
inside the SDK: lesson 4 shows what an SDK retry looks like in a trace, which is nothing at all.

And the reply is wrong. The documents say returns are free, and the next section finds out where the
mistake came from.

## Why spans, and not log lines

The same facts could be written as five log lines with timestamps. What the trace adds is the
**parent**: every span knows which span it ran inside. That is what lets a tool draw the tree,
subtract a child's time from its parent's, and find all the spans of one request among the spans of
a thousand others running at the same time. A timestamp cannot do that once two requests overlap.
`observability` lesson 11 reads traces of a web shop the same way; the difference here is only what
the slowest span usually is.
