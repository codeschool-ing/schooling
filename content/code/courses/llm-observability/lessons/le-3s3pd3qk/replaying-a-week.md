---
title: A week of production, replayed
version: 2
---

Cost, latency and quality are questions about many requests, and lessons 1 and 2 had a handful. From
here on the course needs a week of production to look at. It has the requests, in
`data/traffic.jsonl`; what it does not have is the week itself. `replay.py`, which lesson 2 saved,
plays the file through the assistant, and this section takes it apart.

**Every request runs for real.** The question is embedded, the documents are searched, the reply is
streamed from `llama3.2:3b`, and every span is measured. Two things are simulated, and the file says
so in its first paragraph. **The calendar**: each request's spans are stamped with the moment the
traffic file gives it rather than the moment the replay ran it, by an offset `telemetry.py` adds to
its clock. **The people**: what a customer does after reading a reply is decided by rules the course
wrote, and lesson 5 is about what those reactions look like in the data.

```schooling-example
{
  "language": "python",
  "file": "replay.py",
  "parts": [
    {
      "code": "\"\"\"replay.py: a week of data/traffic.jsonl through the assistant, in under an hour.\n\n    python replay.py [--from 2026-09-28] [--to 2026-10-05] [--workers 1] [--processor MODULE:CLASS]\n\nEach request runs for real: the embedding, the search, the streamed reply, all\nmeasured. What is simulated is the calendar and the people. The calendar:\nevery span is stamped with the moment the traffic file gives its request, and\nthe durations inside it are the measured ones. The people: what a customer\ndoes after reading a reply is decided by the rules below, which the course\nwrote, with a generator seeded by the request's id so that a rerun decides\nthe same way. They are written down so that nobody mistakes them for a\nmeasurement of how people behave.\n\n  - A reply is RIGHT if it contains one of its topic's facts, or, for a topic\n    the documents do not answer, if it contains the refusal.\n  - 25% of customers rate a reply. A wrong reply gets a thumbs down 85% of the\n    time; a right one gets a thumbs up 92% of the time.\n  - After a wrong reply, 45% ask again in other words, 40 to 120 seconds\n    later, in the same session. If that is wrong too, 60% ask for a person.\n  - Summaries are for the support team, who do not rate them.\n\nFeedback is appended to feedback.jsonl, keyed by the trace id of the reply it\nis about.\n\"\"\"\n",
      "note": "The rules the simulated people follow, written at the top so that nobody mistakes them for a measurement of how people behave."
    },
    {
      "code": "import argparse\nimport importlib\nimport json\nimport random\nimport threading\nfrom concurrent.futures import ThreadPoolExecutor\nfrom datetime import datetime, timedelta\n\nimport assistant\nimport telemetry\n\np = argparse.ArgumentParser()\np.add_argument(\"--traffic\", default=\"data/traffic.jsonl\")\np.add_argument(\"--from\", dest=\"since\", default=\"0000\")\np.add_argument(\"--to\", dest=\"until\", default=\"9999\")\np.add_argument(\"--workers\", type=int, default=1)\np.add_argument(\"--spans\", default=\"spans.jsonl\")\np.add_argument(\"--processor\", action=\"append\", default=[], help=\"MODULE:CLASS, a span processor to add\")\na = p.parse_args()\n\nTOPICS = json.load(open(\"data/topics.json\"))\nLOCK = threading.Lock()\ncounts = {\"requests\": 0, \"errors\": 0, \"feedback\": 0}\n\n\n"
    },
    {
      "code": "def right(reply, topic):\n    facts = TOPICS[topic - 1][\"facts\"]\n    if not facts:\n        return assistant.REFUSAL in reply\n    return any(f.lower() in reply.lower() for f in facts)\n\n\n",
      "note": "What decides whether a reply was right, for the simulated customer: one of its topic's facts is in it, or, for a question the documents do not answer, it contains the refusal."
    },
    {
      "code": "def record(**row):\n    with LOCK, open(\"feedback.jsonl\", \"a\") as f:\n        f.write(json.dumps(row) + \"\\n\")\n        counts[\"feedback\"] += 1\n\n\n",
      "note": "Each reaction is one line in `feedback.jsonl`, carrying the trace id of the reply it is about."
    },
    {
      "code": "def one(row, at, text):\n    \"\"\"Ask, as if at AT; (reply, trace id), or (None, None) if the assistant failed.\"\"\"\n    t = datetime.fromisoformat(at)\n    token = telemetry.OFFSET_NS.set(int(t.timestamp() * 1e9) - telemetry.time.time_ns())\n    try:\n        reply, _, trace_id = assistant.ask(text, user=row[\"user\"], session=row[\"session\"],\n                                           feature=row[\"feature\"], at=at)\n        return reply, trace_id\n    except Exception:\n        with LOCK:\n            counts[\"errors\"] += 1\n        return None, None\n    finally:\n        telemetry.OFFSET_NS.reset(token)\n        with LOCK:\n            counts[\"requests\"] += 1\n\n\n",
      "note": "One request, asked as if at AT. The offset is the difference between that moment and now, set for this thread only; every span the assistant opens while it is set carries the traffic file's time, and its duration is the measured one."
    },
    {
      "code": "def person(row):\n    rng = random.Random(row[\"id\"])\n    reply, trace_id = one(row, row[\"at\"], row[\"text\"])\n    if row[\"feature\"] == \"summary\" or reply is None:\n        return\n    ok = right(reply, row[\"topic\"])\n    t = datetime.fromisoformat(row[\"at\"])\n    if rng.random() < 0.25:\n        up = rng.random() < 0.92 if ok else rng.random() >= 0.85\n        record(trace=trace_id, request=row[\"id\"], at=(t + timedelta(seconds=rng.randrange(5, 30))).isoformat(),\n               kind=\"thumbs\", value=\"up\" if up else \"down\")\n    if ok or rng.random() >= 0.45:\n        return\n    t += timedelta(seconds=rng.randrange(40, 121))\n    others = [x for x in TOPICS[row[\"topic\"] - 1][\"phrasings\"] if x != row[\"text\"]] or [row[\"text\"]]\n    again = rng.choice(others)\n    record(trace=trace_id, request=row[\"id\"], at=t.isoformat(), kind=\"rephrase\", value=again)\n    reply2, trace2 = one(row, t.isoformat(timespec=\"seconds\"), again)\n    if reply2 is not None and not right(reply2, row[\"topic\"]) and rng.random() < 0.6:\n        record(trace=trace2, request=row[\"id\"], at=(t + timedelta(seconds=20)).isoformat(),\n               kind=\"escalate\", value=\"asked for a person\")\n\n\n",
      "note": "One customer: ask, maybe rate, maybe ask again in other words, maybe ask for a person. The generator is seeded with the request's id, so a rerun decides the same way."
    },
    {
      "code": "telemetry.setup(a.spans, processors=[getattr(importlib.import_module(m), c)() for m, c in\n                                     (x.split(\":\") for x in a.processor)])\nrows = [r for r in map(json.loads, open(a.traffic)) if a.since <= r[\"at\"] < a.until]\nwith ThreadPoolExecutor(a.workers) as pool:\n    list(pool.map(person, rows))\nprint(f\"replayed {len(rows)} requests from {a.traffic}: {counts['requests']} asked, \"\n      f\"{counts['errors']} failed, {counts['feedback']} feedback events\")\n",
      "note": "One request at a time by default, because Ollama on one computer answers one at a time: several at once would only queue there, and every wait in the queue would be measured as the model being slow."
    }
  ]
}
```

```
ana@dev:~/obs$ python replay.py
replayed 284 requests from data/traffic.jsonl: 311 asked, 0 failed, 89 feedback events
ana@dev:~/obs$ wc -l spans.jsonl feedback.jsonl
  1666 spans.jsonl
    89 feedback.jsonl
  1755 total
```

284 requests in the file became 311 questions to the assistant: the other 27 are customers asking
again in other words after a wrong answer, which the rules let 45% of them do. Nothing failed. The
replay took 17 minutes on the recording machine. 1,666 spans went to `spans.jsonl` and 89 reactions
to `feedback.jsonl`: thumbs, rephrasings and requests for a person.

The first trace of the week, a summary the support team asked for early on Monday:

```
ana@dev:~/obs$ python tree.py --attrs $(head -1 spans.jsonl | python -c "import json,sys; print(json.load(sys.stdin)[\"trace\"])") | head -12
trace a29f0116fe1e3be0426f246294af1ba2   start(ms) took(ms)
      0   4,930 ms  ask
                     app.feature = "summary"
                     app.release = "2026.09.4"
                     gen_ai.request.model = "llama3.2:3b"
                     user.hash = "f71cf97066359de1"
                     session.id = "s001"
                     app.question = "Summarise this conversation in at most 40 words.\nHello, this is Rafael Lima. My order [order] has not arrived.\nIt was sent by standard delivery and the tracking has not changed for twelve working days.\nI would prefer a refund rather than waiting for a new parcel."
                     app.outcome = "summarised"
                     app.reply = "Rafael Lima is contacting customer service regarding a missing order ([order]) that has not arrived after 12 working days. He prefers a refund over waiting for a new parcel."
      0   4,929 ms    generate
                       app.attempts = 1
```

Its release is `2026.09.4`, the one before the floor was raised, because on Monday 28 September that
was the release in force; `assistant.py` picks the release by the request's time, not by today's. A
summary searches nothing, so its only child is `generate`.

Read its question and its reply. The order number was redacted on the way in, as lesson 2 arranged.
**The customer's name was not, and the model repeated it in the summary**, so it is on the span
twice. Lesson 2 said a name has no shape a pattern can find; here is a week's first trace proving
it.

## Why replay, and not a load test

A load test sends many requests to find where a system breaks. A replay sends **the requests that
happened** to find out what they cost, how long they took and what they got back. The difference is
in the input: a replay is only as representative as the traffic it plays, and the traffic here is a
week the course invented. What it is good for is what this course uses it for: a fixed, repeatable
week that every later lesson can measure, change and measure again, where a real production week
would never come back.
