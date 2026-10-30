---
title: A log line that Cloud Logging can read
version: 1
---

**Cloud Logging stores entries, and an entry is either a string or a structure.** Cloud Run, GKE and
Cloud Functions collect whatever a container writes on its standard output and standard error and send it to
Cloud Logging without an agent or a library. What becomes of each line depends on its shape: a line that is
one JSON object becomes a **structured** entry, `jsonPayload`, whose fields can be searched one by one, and
a handful of those fields mean something to Cloud Logging itself. Any other line becomes `textPayload`, one
string, searchable only as text. **Nothing in this lesson reaches Cloud Logging**: there is no emulator for
it. What runs here is the program that writes the lines, and the questions Cloud Logging would answer, asked
of those lines on your computer.

The program below writes two lines the way the shop's API should, and one the way it should not. Write it
into `~/gcp/logdemo.py`:

```python
# logdemo.py
"""logdemo.py: three lines of the shop's API, written the way Cloud Logging reads them.

Cloud Run and GKE send whatever a container writes on stdout to Cloud Logging.
A line that is a JSON object becomes a structured entry, and a few of its
fields have a meaning there; anything else becomes plain text.
"""
import json
import sys


def log(severity, message, **fields):
    entry = {"severity": severity, "message": message, **fields}
    print(json.dumps(entry), file=sys.stdout, flush=True)


log("INFO", "order placed", order_id="o-1001", total_cents=4380,
    httpRequest={"requestMethod": "POST", "requestUrl": "/orders",
                 "status": 201, "latency": "0.084s"},
    **{"logging.googleapis.com/trace":
       "projects/planner-dev/traces/4bf92f3577b34da6a3ce929d0e0e4736"})
log("WARNING", "payment retried", order_id="o-1002", attempt=2)
print("level=error msg=\"stock lookup failed\" product=p-002", flush=True)
```

```
ana@laptop:~/gcp$ python3 logdemo.py
{"severity": "INFO", "message": "order placed", "order_id": "o-1001", "total_cents": 4380, "httpRequest": {"requestMethod": "POST", "requestUrl": "/orders", "status": 201, "latency": "0.084s"}, "logging.googleapis.com/trace": "projects/planner-dev/traces/4bf92f3577b34da6a3ce929d0e0e4736"}
{"severity": "WARNING", "message": "payment retried", "order_id": "o-1002", "attempt": 2}
level=error msg="stock lookup failed" product=p-002
```

## What Cloud Logging makes of each line

Cloud Logging would turn the first two lines into structured entries and the third into a string. The same
conversion, done on your computer with `jq`, shows what each entry's severity would be:

```
ana@laptop:~/gcp$ python3 logdemo.py | jq -c -R 'fromjson? // {textPayload: .}' | jq -c '{severity: (.severity // "DEFAULT"), message: (.message // .textPayload)}'
{"severity":"INFO","message":"order placed"}
{"severity":"WARNING","message":"payment retried"}
{"severity":"DEFAULT","message":"level=error msg=\"stock lookup failed\" product=p-002"}
```

**The third line says `level=error` and arrives as severity `DEFAULT`.** Cloud Logging reads a severity
only from a JSON field called `severity`; a line that is not JSON, or JSON that calls it `level`, has none,
and an alert on "errors" never sees it. It is the commonest mistake in this lesson and it is invisible: the
line is there, readable, with the word *error* in it, and filtered out by every query that asks for errors.
This platform's own logger had exactly that defect, writing `level` where Cloud Logging reads `severity`,
until somebody read a log for another reason.

The fields Cloud Logging gives a meaning to, in a JSON line:

| field | becomes |
|---|---|
| `severity` | the entry's severity: `DEBUG`, `INFO`, `NOTICE`, `WARNING`, `ERROR`, `CRITICAL`, `ALERT`, `EMERGENCY` |
| `message` | the text shown for the entry in a list of results |
| `httpRequest` | the entry's HTTP request: method, URL, status, latency, which the console draws as a request |
| `logging.googleapis.com/trace` | the trace this entry belongs to, which lesson 11 follows from a log line to a trace |
| `logging.googleapis.com/labels` | labels on the entry, searchable without reading the payload |

Everything else stays in `jsonPayload`, searchable by name: `jsonPayload.order_id="o-1002"`. **One line,
one JSON object, no line breaks inside it.** A stack trace printed over twenty lines arrives as twenty
entries of plain text; lesson 11 is about writing it inside one entry instead.
