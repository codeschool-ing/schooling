---
title: Prices, and scores
version: 2
---

## Teaching it the model's price

Langfuse prices a generation by matching its model name against a table of **model definitions**, each
with a price per input and output token and a start date. It ships with definitions for the
providers' models and none for a model that runs on your own machine. `lf_prices.py` creates them
from lesson 3's `prices.json`, both of `llama3.2:3b`'s prices with their dates:

```python
"""lf_prices.py: llama3.2:3b's two prices from prices.json, as model definitions in Langfuse."""
import base64
import json
import os
import urllib.request

KEY = f"{os.environ['LANGFUSE_PUBLIC_KEY']}:{os.environ['LANGFUSE_SECRET_KEY']}"
for i, p in enumerate(json.load(open("prices.json"))["models"]["llama3.2:3b"]):
    name = "llama3.2:3b" if i == 0 else f"llama3.2:3b from {p['from']}"   # a model's name is unique in a project
    body = {"modelName": name, "matchPattern": r"(?i)^llama3\.2:3b$", "startDate": p["from"] + "T00:00:00-03:00",
            "unit": "TOKENS", "inputPrice": float(p["input"]) / 1e6, "outputPrice": float(p["output"]) / 1e6}
    request = urllib.request.Request(os.environ["LANGFUSE_BASE_URL"] + "/api/public/models", data=json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json",
                                              "Authorization": "Basic " + base64.b64encode(KEY.encode()).decode()})
    m = json.load(urllib.request.urlopen(request))
    print("model", m["modelName"], "from", m["startDate"], "input", m["inputPrice"], "output", m["outputPrice"])
```

Why two names: a model's name is unique in a Langfuse project, and sending the second price under
the same name fails with `Model name ... already exists in project`. So a second price for the same
model is a second definition under another name, matching the same pattern, with a later start date.

Then Friday is replayed, with `spans.jsonl` emptied first so that it holds Friday alone:

```
ana@dev:~/obs$ python lf_prices.py
model llama3.2:3b from 2026-01-01T03:00:00.000Z input 2e-06 output 8e-06
model llama3.2:3b from 2026-09-30 from 2026-09-30T03:00:00.000Z input 1.5e-06 output 6e-06
ana@dev:~/obs$ export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$LANGFUSE_BASE_URL/api/public/otel/v1/traces OTEL_EXPORTER_OTLP_TRACES_HEADERS="Authorization=Basic $(printf %s $LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY | base64 -w0)"; rm spans.jsonl; python replay.py --from 2026-10-02 --to 2026-10-03 --processor lf_names:LangfuseNames
replayed 46 requests from data/traffic.jsonl: 48 asked, 0 failed, 14 feedback events
ana@dev:~/obs$ python lf.py daily
2026-10-05    3 traces cost 0
2026-10-04   35 traces cost 0
2026-10-03   37 traces cost 0.001884
2026-10-02   43 traces cost 0.014011
ana@dev:~/obs$ python -c "import costs; print(sum(r[\"cost\"] for r in costs.requests()))"
0.01590828
```

Three things to read in that.

**Saturday and Sunday still cost 0.** They were sent before the prices existed, and Langfuse works out
cost **when it receives a generation**, not when it is read. Adding a price later does not reprice what
is already stored. That is the opposite of `costs.py`, which keeps tokens and prices apart and
multiplies when it is asked, for exactly this reason: in lesson 3 the price of 30 September could be
applied to every request after it, whenever it was entered.

**Friday's cost is in two days**, 2 and 3 October, because the dates are UTC: the shop's Friday evening
after nine is Saturday in UTC. A report by day from this API and one from `bill.py` will disagree at
every midnight, and both are right.

**The totals agree, nearly.** Langfuse's two days add up to 0.015895 dollars; `costs.py` over the
same spans says 0.01590828. Nearly all of the difference is the embeddings: Friday's 639 embedding
tokens at 0.02 per million are 0.00001278, which `costs.py` counts and Langfuse was given no price
for, and the last half a millionth is `lf.py` rounding each day to six places. Two systems computing
the same bill is a good check on both, and the difference names what one of them is missing.

## Scores

A **score** in Langfuse is a value attached to a trace, or to one observation in it: a number, a
category, a boolean, a piece of text, each with a name. Thumbs are the obvious first one. Every
thumb in `feedback.jsonl` already carries its trace id, and the trace ids of OpenTelemetry are the
trace ids of Langfuse, so sending them is a loop:

```python
"""lf_scores.py: every thumb in feedback.jsonl, sent to Langfuse as a score on the trace it is about."""
import json

from langfuse import get_client

langfuse = get_client()
sent = 0
for f in map(json.loads, open("feedback.jsonl")):
    if f["kind"] == "thumbs":
        langfuse.create_score(trace_id=f["trace"], name="thumbs", value=1 if f["value"] == "up" else 0,
                              data_type="BOOLEAN")
        sent += 1
langfuse.flush()
print(sent, "scores sent")
```

```
ana@dev:~/obs$ python lf_scores.py
20 scores sent
ana@dev:~/obs$ python lf.py scores thumbs
20 scores named thumbs: 17 of value 1, 3 of value 0
```

Twenty thumbs from the three days replayed, seventeen up and three down, each now on the trace it
judges. From here a screen can filter traces by score, chart the share of thumbs down per day, or
list the traces with a thumbs down and no judge score yet. Lesson 9 adds a judge's verdicts as a
second score on the same traces, and lesson 10 a person's, and the reason all three can sit side by
side is that all three were joined by id from the start.