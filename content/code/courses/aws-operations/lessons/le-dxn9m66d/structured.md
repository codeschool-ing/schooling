---
title: Structured lines, written to be queried
version: 1
---

A log line written for a person to read, `checkout failed for c-1027 after 512ms`, is easy to write and
hard to ask questions of: every question becomes a regular expression that breaks when somebody edits
the sentence. **A line written as JSON is a record**, with fields a query can name. The shop's API
writes one object per request: the status, the path, the latency and the customer.

There is no real API in this lab, so the lines come from a program that writes 300 of them the way
the API would, with a fixed seed so that the counts in this section are the same every time it runs.
`/checkout` fails 6% of its requests and is slow 8% of the time, `/cart` fails 2%:

```python
# traffic.py: 300 log lines from the shop's API, as CloudWatch Logs events
import json
import random
import time

rng = random.Random(7)
now = int(time.time() * 1000)
paths = ["/", "/cart", "/checkout", "/search"]
failing = {"/checkout": 0.06, "/cart": 0.02}

events = []
for i in range(300):
    path = rng.choice(paths)
    slow = path == "/checkout" and rng.random() < 0.08
    line = {
        "status": 503 if rng.random() < failing.get(path, 0) else 200,
        "path": path,
        "ms": rng.randint(700, 1500) if slow else rng.randint(20, 90),
        "customer": f"c-{rng.randint(1000, 1039)}",
    }
    events.append({"timestamp": now - (300 - i) * 1000, "message": json.dumps(line)})

print(json.dumps(events))
```

The output is already in the shape `put-log-events` takes: a list of events, each a timestamp in
milliseconds and a message.

```
ana@laptop:~/aws/logs$ python3 traffic.py > events.json
ana@laptop:~/aws/logs$ jq length events.json && jq -r '.[0].message' events.json
300
{"status": 200, "path": "/checkout", "ms": 26, "customer": "c-1004"}
ana@laptop:~/aws/logs$ aws logs create-log-stream --log-group-name /shop/api --log-stream-name api-1
ana@laptop:~/aws/logs$ aws logs put-log-events --log-group-name /shop/api --log-stream-name api-1 --log-events file://events.json --query 'rejectedLogEventsInfo'
null
```

`rejectedLogEventsInfo` is `null`: every event was accepted. CloudWatch refuses events older than 14
days or more than two hours in the future, and says so in that field, which is worth checking in any
program that sends logs.

## Filter patterns

`filter-log-events` takes a **filter pattern**, a small language of its own: a bare word matches lines
containing it, and `{ $.status >= 500 }` matches JSON lines whose `status` field is 500 or more.

```
ana@laptop:~/aws/logs$ aws logs filter-log-events --log-group-name /shop/api --filter-pattern '{ $.status >= 500 }' --query 'length(events)'
300
ana@laptop:~/aws/logs$ aws logs filter-log-events --log-group-name /shop/api --filter-pattern 'checkout' --query 'length(events)'
69
```

The word matched 69 lines, the requests to `/checkout`. **The JSON pattern matched all 300**, which is
wrong: only a handful of lines have a status of 500 or more. moto applies plain-word patterns and
ignores JSON ones. On AWS the second command would count the errors, which is what the next section
does another way.
