---
title: A chain of calls
version: 1
---

One call is rarely the whole of an answer. Marginalia's assistant does four things for every
question: it turns the question into a vector, searches the documents with it, asks the model to
answer from what it found, and checks the citations in the reply. Two of those are calls to a
provider, one is a database query, and one is plain Python. A trace of the request gives each its
own span and nests them under one root, so that a slow or failed answer can be taken apart.

`assistant.py` is `rag` lesson 9's `rag.py` with that done to it. Every span is opened by one small
function in `telemetry.py`:

```schooling-example
{
  "language": "python",
  "file": "telemetry.py",
  "parts": [
    {
      "code": "@contextlib.contextmanager\ndef span(name, **attributes):\n    \"\"\"A span stamped with the lab's clock, marked as an error if the block raises.\"\"\"\n    s = tracer.start_span(name, attributes=attributes or None, start_time=now_ns())\n    with trace.use_span(s, end_on_exit=False):\n        try:\n            yield s\n        except BaseException as e:\n            s.set_status(Status(StatusCode.ERROR, f\"{type(e).__name__}: {e}\"))\n            s.record_exception(e, timestamp=now_ns())\n            raise\n        finally:\n            s.end(end_time=now_ns())",
      "note": "`span()` is the one way the assistant opens a span. It stamps the start and the end with the lab's clock, which lesson 3 needs, and if the block raises, it marks the span as an error and records the exception before letting it through."
    }
  ]
}
```

And these are the parts of the assistant that open them:

```schooling-example
{
  "language": "python",
  "file": "assistant.py",
  "parts": [
    {
      "code": "def retrieve(question, cfg):\n    with span(\"embed\", **{\"gen_ai.operation.name\": \"embeddings\", \"gen_ai.request.model\": \"lab-minilm\"}) as s:\n        r = client.embeddings.create(model=\"lab-minilm\", input=[question])\n        s.set_attribute(\"gen_ai.usage.input_tokens\", r.usage.prompt_tokens)\n    with span(\"search\", **{\"db.system.name\": \"postgresql\", \"app.search.k\": cfg[\"k\"],\n                           \"app.search.floor\": cfg[\"floor\"]}) as s:\n        rows = db.execute(\n            \"SELECT id, path, text, updated, 1 - (embedding <=> %s::vector) AS score FROM chunks\"\n            \" WHERE status = 'current' AND audience = 'public'\"\n            \" ORDER BY embedding <=> %s::vector LIMIT %s\",\n            (r.data[0].embedding, r.data[0].embedding, cfg[\"k\"])).fetchall()\n        kept = [row for row in rows if row[4] >= cfg[\"floor\"]]\n        s.set_attribute(\"app.search.returned\", len(rows))\n        s.set_attribute(\"app.search.kept\", len(kept))\n        if rows:\n            s.set_attribute(\"app.search.top_score\", round(rows[0][4], 3))\n        s.set_attribute(\"app.search.chunks\", [row[0] for row in kept])\n    return kept",
      "note": "Retrieval is two spans, because it is two operations with different ways of going wrong: the embedding is a call to a provider, the search a query to PostgreSQL. The search span records how many chunks came back and how many cleared the floor, and which ones."
    },
    {
      "code": "def chat(model, messages, max_tokens):\n    \"\"\"One attempt: a streamed completion, with the time to its first token.\"\"\"\n    with span(f\"chat {model}\", **{\"gen_ai.operation.name\": \"chat\", \"gen_ai.provider.name\": \"openai\",\n                                  \"gen_ai.request.model\": model, \"gen_ai.request.max_tokens\": max_tokens}) as s:\n        started, first, parts, finish, usage = time.monotonic(), None, [], None, None\n        stream = client.chat.completions.create(model=model, max_tokens=max_tokens, messages=messages,\n                                                stream=True, stream_options={\"include_usage\": True})\n        for chunk in stream:\n            if chunk.usage:\n                usage = chunk.usage\n            for c in chunk.choices:\n                if c.delta.content:\n                    if first is None:\n                        first = time.monotonic()\n                        event(\"gen_ai.first_token\")\n                    parts.append(c.delta.content)\n                finish = c.finish_reason or finish\n        if first is not None:\n            s.set_attribute(\"app.time_to_first_token_ms\", round((first - started) * 1000))\n        if usage:\n            s.set_attribute(\"gen_ai.usage.input_tokens\", usage.prompt_tokens)\n            s.set_attribute(\"gen_ai.usage.output_tokens\", usage.completion_tokens)\n        if finish is None:\n            s.set_attribute(\"app.partial_pieces\", len(parts))\n            raise IncompleteReply(f\"stream ended after {len(parts)} pieces with no finish reason\")\n        s.set_attribute(\"gen_ai.response.model\", chunk.model)\n        s.set_attribute(\"gen_ai.response.finish_reasons\", [finish])\n        return \"\".join(parts)",
      "note": "One attempt at the model. The request is streamed, as it is to a customer's screen, so the span can record when the first piece of text arrived as well as when the last did. Lesson 4 needs both."
    },
    {
      "code": "def ask(question, user=\"anonymous\", session=None, feature=\"help\", at=None):\n    at = at or datetime.now().isoformat(timespec=\"seconds\")\n    release, cfg = release_at(at)\n    with span(\"ask\", **{\"app.feature\": feature, \"app.release\": release, \"gen_ai.request.model\": cfg[\"model\"],\n                        \"user.hash\": redact.pseudonym(user), \"session.id\": session or \"\",\n                        \"app.question\": redact.redact(question)}) as root:\n        if feature == \"summary\":\n            reply = generate([{\"role\": \"user\", \"content\": question}], cfg[\"model\"], max_tokens=120)\n            outcome, sources = \"summarised\", []\n        else:\n            sources = retrieve(question, cfg)\n            if not sources:\n                reply, outcome = REFUSAL, \"refused\"\n            else:\n                numbered = \"\\n\\n\".join(f\"[{n}] {path} (updated {updated})\\n{text}\"\n                                       for n, (_, path, text, updated, _) in enumerate(sources, 1))\n                reply = generate([{\"role\": \"system\", \"content\": SYSTEM},\n                                  {\"role\": \"user\", \"content\": f\"{numbered}\\n\\nQuestion: {question}\"}],\n                                 cfg[\"model\"])\n                outcome = \"refused\" if reply.startswith(REFUSAL) else \"answered\"\n            with span(\"check_citations\") as c:\n                cited = [int(n) for n in re.findall(r\"\\[(\\d+)\\]\", reply)]\n                c.set_attribute(\"app.citations.count\", len(cited))\n                c.set_attribute(\"app.citations.dangling\", sum(1 for n in cited if not 0 < n <= len(sources)))\n        root.set_attribute(\"app.outcome\", outcome)\n        root.set_attribute(\"app.reply\", redact.redact(reply))\n        trace_id = f\"{root.get_span_context().trace_id:032x}\"\n    return reply, sources, trace_id",
      "note": "The root span carries what the whole request was: the feature, the release, the model, who asked (as a keyed hash, lesson 2) and the question. Everything else opens inside it and becomes its child, without being told: `span()` makes each new span current, and a span started while another is current takes it as its parent."
    }
  ]
}
```

## The trace

```
ana@lab:~/obs$ python assistant.py "Above what order value is standard delivery free?"
Express delivery is not free at any order value. [1]
trace 1a218c3902fa97519a4b28d0bd1f155f
ana@lab:~/obs$ python tree.py
trace 1a218c3902fa97519a4b28d0bd1f155f   start(ms) took(ms)
      0     785 ms  ask
      0      56 ms    embed
     56       4 ms    search
     61     723 ms    generate
     61     723 ms      chat extract-1
    784       0 ms    check_citations
```

`tree.py` reads the spans the assistant wrote to `spans.jsonl` and draws them as the tree they are:
each line is a span, indented under its parent, with when it started, counted from the start of the
trace, and how long it took. It is forty lines, and it is in the lab beside the others; lessons 6 and
7 replace it with tools that draw the same thing on a screen.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The trace of one answered question as bars on a time axis from 0 to 800 ms. ask spans the whole 785 ms. Under it, embed takes 56 ms, search 4 ms, generate 723 ms, and check_citations under a millisecond at the end. Inside generate, one chat extract-1 span of the same length, whose first token arrived at 386 ms.\"><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ask</text><rect x=\"170\" y=\"22\" width=\"510.25\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"178\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">785 ms</text><text x=\"34\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">embed</text><rect x=\"170\" y=\"52\" width=\"36.4\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"212.4\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">56 ms</text><text x=\"34\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">search</text><rect x=\"206.4\" y=\"82\" width=\"2.6\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"215\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 ms</text><text x=\"34\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">generate</text><rect x=\"209.65\" y=\"112\" width=\"469.95\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"217.65\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">723 ms</text><text x=\"48\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">chat extract-1</text><rect x=\"209.65\" y=\"142\" width=\"469.95\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"217.65\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">723 ms</text><text x=\"34\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check_citations</text><rect x=\"679.6\" y=\"172\" width=\"2\" height=\"20\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"687.6\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;1 ms</text><path d=\"M420.9 163 L420.9 169\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"424.9\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">first token, 325 ms into the call</text><path d=\"M170 208 L690 208\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 208 L170 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"170\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M300 208 L300 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"300\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M430 208 L430 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"430\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><path d=\"M560 208 L560 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"560\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600</text><path d=\"M690 208 L690 213\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">800</text><text x=\"430\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milliseconds since the trace started</text></svg>", "caption": "Nine tenths of the time is one span, and almost half of that is the wait for the first token."}
```

The shape says three things at a glance.

**The spans add up.** `ask` took 785 ms, and its children took 56, 4, 723 and under 1, one after the
other. Nothing ran in parallel and nothing is missing: a gap between two children would be time the
code spent somewhere that has no span, which is the first thing to look for in a trace that does not
add up.

**One span is nearly all of it.** The model call took 723 of the 785 ms. Making the search twice as
fast would save 2 ms; making the answer shorter would save hundreds. A trace is how that
argument is had with numbers instead of opinions, and lesson 4 has it properly.

**`generate` and `chat extract-1` are the same length** because the call succeeded at the first
attempt. If the provider had refused it, `generate` would have had two or three `chat` children, one
per attempt, and the time between them. That is why the retries are in the assistant's code and not
inside the SDK: lesson 4 shows what an SDK retry looks like in a trace, which is nothing at all.

## Why spans, and not log lines

The same facts could be written as five log lines with timestamps. What the trace adds is the
**parent**: every span knows which span it ran inside. That is what lets a tool draw the tree,
subtract a child's time from its parent's, and find all the spans of one request among the spans of
a thousand others running at the same time, which a timestamp cannot do once two requests overlap.
`observability` lesson 11 reads traces of a web shop the same way; the difference here is only what
the slowest span usually is.
