---
title: The same spans, sent to Langfuse
version: 2
---

Langfuse receives OpenTelemetry traces at `/api/public/otel`, authenticated with the project's two
keys. So the assistant needs **no new code** to use it: lesson 1's `telemetry.py` already adds an OTLP
exporter whenever `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` is set, and the SDK reads the headers from
`OTEL_EXPORTER_OTLP_TRACES_HEADERS`. Two environment variables, and the replay of Sunday goes to both
the file and Langfuse:

```
ana@dev:~/obs$ export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=$LANGFUSE_BASE_URL/api/public/otel/v1/traces OTEL_EXPORTER_OTLP_TRACES_HEADERS="Authorization=Basic $(printf %s $LANGFUSE_PUBLIC_KEY:$LANGFUSE_SECRET_KEY | base64 -w0)"; python replay.py --from 2026-10-04 --to 2026-10-05
replayed 32 requests from data/traffic.jsonl: 34 asked, 0 failed, 7 feedback events
```

`lf.py` asks Langfuse's public API a few questions and prints one line per answer, so that a terminal
can show what a screen would:

```python
"""lf.py: a few questions to Langfuse's public API, one line per answer."""
import base64
import json
import os
import sys
import urllib.request

KEY = f"{os.environ['LANGFUSE_PUBLIC_KEY']}:{os.environ['LANGFUSE_SECRET_KEY']}"
AUTH = {"Authorization": "Basic " + base64.b64encode(KEY.encode()).decode()}


def get(path):
    request = urllib.request.Request(os.environ["LANGFUSE_BASE_URL"] + path, headers=AUTH)
    return json.load(urllib.request.urlopen(request))


what = sys.argv[1]
if what == "traces":   # traces DAY N: the first N traces of DAY, a local date
    day = f"fromTimestamp={sys.argv[2]}T03:00:00Z&toTimestamp={sys.argv[2]}T23:59:59Z"
    for t in get(f"/api/public/traces?{day}&limit={sys.argv[3]}&orderBy=timestamp.asc")["data"]:
        print(t["timestamp"][:19], t["id"][:8], t["name"], "user", t["userId"], "session", t["sessionId"],
              "cost", t["totalCost"], "input", repr(t["input"]))
elif what == "observations":   # observations TRACE: every observation of one trace, by its full id
    trace = sys.argv[2]
    for o in sorted(get(f"/api/public/observations?traceId={trace}")["data"], key=lambda o: o["startTime"]):
        print(f"{o['type']:10} {o['name']:16} model {o['model']}  usage {o['usageDetails']}  cost {o['calculatedTotalCost']}")
elif what == "daily":
    for d in get("/api/public/metrics/daily")["data"]:
        print(d["date"], f"{d['countTraces']:4} traces", "cost", round(d["totalCost"], 6))
elif what == "scores":
    values = [s["value"] for s in get(f"/api/public/v2/scores?name={sys.argv[2]}&limit=100")["data"]]
    print(f"{len(values)} scores named {sys.argv[2]}: {values.count(1)} of value 1, {values.count(0)} of value 0")
```

```
ana@dev:~/obs$ python lf.py traces 2026-10-04 1
2026-10-04T04:46:31 6f657657 ask user None session s253 cost 0 input None
ana@dev:~/obs$ python lf.py observations 40070c68d30ca27981bb60d5a853480f
EMBEDDING  embed            model all-minilm  usage {'input': 5, 'total': 5}  cost 0
GENERATION ask              model llama3.2:3b  usage {}  cost 0
GENERATION chat llama3.2:3b model llama3.2:3b  usage {'input': 160, 'output': 16, 'total': 176}  cost 0
SPAN       search           model None  usage {}  cost 0
SPAN       generate         model None  usage {}  cost 0
SPAN       check_citations  model None  usage {}  cost 0
```

The traces arrived, with their observations: Langfuse's word for spans. The first of Sunday is "Can
I place an order by phone?", which the documents do not answer and the assistant refused without
calling the model, so the second command asks about the first trace that did reach it. It needs the
full id, and `grep -m1 '"name": "chat' spans.jsonl` prints the first chat span with it. Times are in
UTC, three hours ahead of São Paulo, so 04:46 on the screen is a quarter to two in the morning in
the shop. And Langfuse has read our names and decided what each span is.

**The embedding became an `EMBEDDING`, and the model call a `GENERATION`**, with the token counts
read from `gen_ai.usage.*`. That is the convention of lesson 1 paying off: nobody told Langfuse what
those attributes mean.

**`ask` became a `GENERATION` too, with no usage.** The root span carries `gen_ai.request.model`
because lesson 1 put the model of the release on it. A span with a model on it looks like a model
call to a tool that reads the convention literally. A dashboard that counted generations would now
count every request twice.

**The session was found, and the user was not.** `session.id` is a name Langfuse reads; `user.hash`,
which lesson 2 chose as the semantic convention's name for a pseudonym, is not one of the names it
looks for. Nor is `app.question`, so the trace has no input.

**And every cost is 0.** Langfuse prices a generation from a table of models it knows, and
`llama3.2:3b` on your own machine is not one it has a price for.

None of this is a fault in either program. It is what happens whenever two pieces of software meet
through a convention that is still young: each reads the names it knows, and the ones it does not are
kept, in Langfuse's case as metadata, and used for nothing. The next section adds the names.
