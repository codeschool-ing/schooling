---
title: Segments, written by hand and read back
version: 1
---

A service instrumented for X-Ray sends a **segment** for each request it handles: a JSON document
with the trace id, its own id, a name, a start and an end, and **subsegments** for the work it waited
on. There are no services in this lab, so the program below writes the two segments the shop's
checkout would produce, the API's and the payments service's, and sends them as the X-Ray SDK or a
collector would. Its durations are fixed; the structure is the real one.

```schooling-example
{"language": "python", "file": "trace.py", "parts": [{"code": "# trace.py: one checkout, traced across two services, sent to X-Ray\nimport json\nimport random\nimport time\n\nimport boto3\n\nrng = random.Random(11)\nstart = time.time()\ntrace_id = f\"1-{int(start):08x}-{rng.getrandbits(96):024x}\"\n\n\ndef new_id():\n    return f\"{rng.getrandbits(64):016x}\"\n\n\napi_id, call_id = new_id(), new_id()\n", "note": "**A trace id has three parts**: the version `1`, the start time in seconds as eight hex digits, and 96 random bits. The time inside the id is what lets X-Ray find a trace by time without an index. Every span gets an id of its own, 64 random bits."}, {"code": "api = {\n    \"trace_id\": trace_id, \"id\": api_id, \"name\": \"shop-api\",\n    \"start_time\": start, \"end_time\": start + 0.512,\n    \"http\": {\"request\": {\"method\": \"POST\", \"url\": \"/checkout\"}, \"response\": {\"status\": 200}},\n    \"subsegments\": [\n        {\"id\": new_id(), \"name\": \"orders-db\",\n         \"start_time\": start + 0.004, \"end_time\": start + 0.031},\n        {\"id\": call_id, \"name\": \"payments\", \"namespace\": \"remote\",\n         \"start_time\": start + 0.035, \"end_time\": start + 0.505},\n    ],\n}\n", "note": "The API's **segment**: its own work from start to end, 512 ms, with two **subsegments** for what it waited on. `namespace: remote` marks the call to another service, and its id, `call_id`, is what the other service will name as its parent."}, {"code": "payments = {\n    \"trace_id\": trace_id, \"id\": new_id(), \"parent_id\": call_id, \"name\": \"payments\",\n    \"start_time\": start + 0.041, \"end_time\": start + 0.498,\n    \"subsegments\": [\n        {\"id\": new_id(), \"name\": \"card-network\", \"namespace\": \"remote\",\n         \"start_time\": start + 0.050, \"end_time\": start + 0.470},\n    ],\n}\n", "note": "The payments service writes **its own segment**, in its own process, with the same `trace_id` and `parent_id` pointing at the API's subsegment. In a real system the two values arrive in the request's `X-Amzn-Trace-Id` header; here they are shared variables."}, {"code": "xray = boto3.client(\"xray\")\nxray.put_trace_segments(TraceSegmentDocuments=[json.dumps(api), json.dumps(payments)])\nprint(trace_id)\n", "note": "Both documents go to X-Ray in one call, as JSON strings. Real services send theirs separately, through a daemon or a collector, and X-Ray joins them by the trace id."}]}
```

```
ana@laptop:~/aws/traces$ TRACE=$(python3 trace.py); echo "$TRACE"
1-6ad25577-8f4d3e27dda1494c73cf256d
```

The trace id begins with `1-`, then the time of the run in hexadecimal, then the random part. X-Ray
accepts the two documents and lists the trace:

```
ana@laptop:~/aws/traces$ aws xray get-trace-summaries --start-time $(date -d '-5 min' +%s) --end-time $(date -d '+1 min' +%s) --query 'TraceSummaries[].[Id,Duration,ResponseTime]' --output text
1-6ad25577-8f4d3e27dda1494c73cf256d	0.0	1.0
```

A duration of 0.0 and a response time of 1.0 seconds, for a request that took 512 milliseconds.
**moto stores the documents and invents the summary**; X-Ray computes both from the segments. What it
does store is enough to read the trace back, and a second short program draws where the time went:

```python
# waterfall.py TRACE_ID: where the time of one trace went
import json
import sys

import boto3

trace = boto3.client("xray").batch_get_traces(TraceIds=[sys.argv[1]])["Traces"][0]
docs = [json.loads(s["Document"]) for s in trace["Segments"]]
t0 = min(d["start_time"] for d in docs)


def ms(t):
    return round((t - t0) * 1000)


def show(span, depth):
    took = ms(span["end_time"]) - ms(span["start_time"])
    print(f'{"  " * depth}{span["name"]:<{18 - 2 * depth}} at {ms(span["start_time"]):>4} ms  took {took:>4} ms')
    for sub in span.get("subsegments", []):
        show(sub, depth + 1)
        for child in docs:
            if child.get("parent_id") == sub["id"]:
                show(child, depth + 2)


for d in docs:
    if "parent_id" not in d:
        show(d, 0)
```

```
ana@laptop:~/aws/traces$ python3 waterfall.py 1-6ad25577-8f4d3e27dda1494c73cf256d
shop-api           at    0 ms  took  512 ms
  orders-db        at    4 ms  took   27 ms
  payments         at   35 ms  took  470 ms
    payments       at   41 ms  took  457 ms
      card-network at   50 ms  took  420 ms
```

Read it from the bottom. The checkout took 512 ms; the database answered in 27; **the card network took
420 of the 512**. Nothing in the API's own metrics says that: its latency is high and its CPU is idle.
The trace says the time was spent waiting two services away, which is a different conversation with a
different team. On AWS, the console draws exactly this waterfall for any trace, and a **service map**
from all of them: a box per service, a line per call, coloured by errors. moto draws neither.

## What instrumentation does for you

Nobody writes segments by hand. An SDK or an agent in each service creates the segment when a request
arrives, a subsegment around each call it makes through an instrumented client (HTTP, the AWS SDK, a
database driver), and **propagates the context**: it adds the trace id and the current span's id to the
outgoing request's header, and the next service's SDK reads them and writes its segment as a child. The
two shared variables in `trace.py` stand for that header.
