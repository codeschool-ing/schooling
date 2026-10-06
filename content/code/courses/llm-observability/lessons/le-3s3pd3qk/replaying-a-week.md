---
title: A week of production, replayed
version: 1
---

Cost, latency and quality are questions about many requests, and lessons 1 and 2 had a handful. From
here on the course needs a week of production to look at. It has the requests, in
`data/traffic.jsonl`; what it does not have is the week itself. `replay.py` plays the file through
the assistant in a few minutes.

**Every request runs for real.** The question is embedded, the documents are searched, the reply is
streamed from labobs, and every span is measured. Two things are simulated, and the file says so in
its first paragraph. **The calendar**: each request's spans are stamped with the moment the traffic
file gives it rather than the moment the replay ran it, by an offset `telemetry.py` adds to its clock.
**The people**: what a customer does after reading a reply is decided by rules the course wrote, and
lesson 5 is about what those reactions look like in the data.

```schooling-example
{
  "language": "python",
  "file": "replay.py",
  "parts": [
    {
      "code": "def right(reply, topic):\n    facts = TOPICS[topic - 1][\"facts\"]\n    if not facts:\n        return reply.startswith(assistant.REFUSAL)\n    return any(f.lower() in reply.lower() for f in facts)",
      "note": "What decides whether a reply was right, for the simulated customer: one of its topic's facts is in it, or, for a question the documents do not answer, it is the refusal."
    },
    {
      "code": "def one(row, at, text):\n    \"\"\"Ask, as if at AT; (reply, trace id), or (None, None) if the assistant failed.\"\"\"\n    t = datetime.fromisoformat(at)\n    token = telemetry.OFFSET_NS.set(int(t.timestamp() * 1e9) - telemetry.time.time_ns())\n    try:\n        reply, _, trace_id = assistant.ask(text, user=row[\"user\"], session=row[\"session\"],\n                                           feature=row[\"feature\"], at=at)\n        return reply, trace_id\n    except Exception:\n        with LOCK:\n            counts[\"errors\"] += 1\n        return None, None\n    finally:\n        telemetry.OFFSET_NS.reset(token)\n        with LOCK:\n            counts[\"requests\"] += 1",
      "note": "One request, asked as if at AT. The offset is the difference between that moment and now, set for this thread only; every span the assistant opens while it is set carries the traffic file's time, and its duration is the measured one."
    },
    {
      "code": "def person(row):\n    rng = random.Random(row[\"id\"])\n    reply, trace_id = one(row, row[\"at\"], row[\"text\"])\n    if row[\"feature\"] == \"summary\" or reply is None:\n        return\n    ok = right(reply, row[\"topic\"])\n    t = datetime.fromisoformat(row[\"at\"])\n    if rng.random() < 0.18:\n        up = rng.random() < 0.92 if ok else rng.random() >= 0.85\n        record(trace=trace_id, request=row[\"id\"], at=(t + timedelta(seconds=rng.randrange(5, 30))).isoformat(),\n               kind=\"thumbs\", value=\"up\" if up else \"down\")\n    if ok or rng.random() >= 0.45:\n        return\n    t += timedelta(seconds=rng.randrange(40, 121))\n    others = [x for x in TOPICS[row[\"topic\"] - 1][\"phrasings\"] if x != row[\"text\"]] or [row[\"text\"]]\n    again = rng.choice(others)\n    record(trace=trace_id, request=row[\"id\"], at=t.isoformat(), kind=\"rephrase\", value=again)\n    reply2, trace2 = one(row, t.isoformat(timespec=\"seconds\"), again)\n    if reply2 is not None and not right(reply2, row[\"topic\"]) and rng.random() < 0.6:\n        record(trace=trace2, request=row[\"id\"], at=(t + timedelta(seconds=20)).isoformat(),\n               kind=\"escalate\", value=\"asked for a person\")",
      "note": "One customer: ask, maybe rate, maybe ask again in other words, maybe ask for a person. The generator is seeded with the request's id, so a rerun decides the same way."
    },
    {
      "code": "telemetry.setup(a.spans, processors=[getattr(importlib.import_module(m), c)() for m, c in\n                                     (x.split(\":\") for x in a.processor)])\nrows = [r for r in map(json.loads, open(a.traffic)) if a.since <= r[\"at\"] < a.until]\nwith ThreadPoolExecutor(a.workers) as pool:\n    list(pool.map(person, rows))\nprint(f\"replayed {len(rows)} requests from {a.traffic}: {counts['requests']} asked, \"\n      f\"{counts['errors']} failed, {counts['feedback']} feedback events\")",
      "note": "Eight at a time, because a week played one request after another would take an hour."
    }
  ]
}
```

```
ana@lab:~/obs$ python replay.py
replayed 1127 requests from data/traffic.jsonl: 1345 asked, 0 failed, 483 feedback events
ana@lab:~/obs$ wc -l spans.jsonl feedback.jsonl
   7224 spans.jsonl
    483 feedback.jsonl
   7707 total
```

1,127 requests in the file became 1,345 questions to the assistant: the other 218 are customers asking
again in other words after a wrong answer, which the rules let 45% of them do. Nothing failed. 7,224
spans went to `spans.jsonl` and 483 reactions to `feedback.jsonl`: thumbs, rephrasings and requests
for a person.

The first trace to finish, an order question from early on Monday:

```
ana@lab:~/obs$ python tree.py --attrs $(head -1 spans.jsonl | python -c "import json,sys; print(json.load(sys.stdin)[\"trace\"])") | head -12
trace 4f220ffffbfefd61b9a1358979bbb5de   start(ms) took(ms)
      0     845 ms  ask
                     app.feature = "order"
                     app.release = "2026.09.4"
                     gen_ai.request.model = "extract-1"
                     user.hash = "e2d8b841e513bb07"
                     session.id = "s0008"
                     app.question = "Hi, I'm Joana Prado ([email]). My order [order] has not arrived after 12 working days. Is it lost?"
                     app.outcome = "refused"
                     app.reply = "I could not find that in our documents."
      0     268 ms    embed
                       gen_ai.operation.name = "embeddings"
```

Its release is `2026.09.4`, the one before the floor was raised, because on Monday 28 September that
was the release in force; `assistant.py` picks the release by the request's time, not by today's.
Its embedding took 268 ms where lesson 1's took 56: eight requests were being replayed at once, and
labembed answers one at a time. That is a property of the replay, not of the week, and it is why
lesson 4 measures latency in the model spans rather than in the whole request.

It is also a refusal, under the old floor. Lesson 5 counts how often that happened to order questions,
and why.

## Why replay, and not a load test

A load test sends many requests to find where a system breaks. A replay sends **the requests that
happened** to find out what they cost, how long they took and what they got back. The difference is
in the input: a replay is only as representative as the traffic it plays, and the traffic here is a
week the course invented. What it is good for is what this course uses it for: a fixed, repeatable
week that every later lesson can measure, change and measure again, where a real production week
would never come back.
