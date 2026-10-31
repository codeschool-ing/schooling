---
title: The query language, asked of three lines
version: 1
---

**A Cloud Logging query is a filter over entries: fields, comparisons and boolean words, with no
`SELECT` and no `FROM`.** It is what the Logs Explorer reads, what a sink selects with, what an exclusion
drops and what a log-based metric counts (lesson 10), so the same expression is written in four places. None
of them can run on your computer. Below, each query is written as Cloud Logging takes it, followed by the
same question asked of `logdemo.py`'s lines with `jq`; **the `jq` is not Cloud Logging**, and its only
purpose is to show which entries the filter selects.

## Severity, and the comparison it allows

```localised
severity>=WARNING
```

Severities are ordered, so `>=` means "this bad or worse". The `jq` equivalent has to list them, because to
`jq` they are only strings:

```
ana@laptop:~/gcp$ python3 logdemo.py | jq -c -R 'fromjson?' | jq -c 'select(.severity == "WARNING" or .severity == "ERROR") | {severity, message, order_id}'
{"severity":"WARNING","message":"payment retried","order_id":"o-1002"}
```

One entry. The third line of the program, the one that says `level=error`, is not there: it has no
severity. This is the previous section's warning, seen from the query's side.

## Fields, and the entry they belong to

```localised
resource.type="cloud_run_revision"
resource.labels.service_name="shop-api"
httpRequest.status>=200
```

Lines written one under another are joined by `AND`. `resource` is where the entry came from, set by the
platform rather than by your code, which makes it the cheapest thing to filter on. `httpRequest.status`
exists only on entries that carry an HTTP request, and an entry without the field does not match, whatever
the comparison:

```
ana@laptop:~/gcp$ python3 logdemo.py | jq -c -R 'fromjson?' | jq -r 'select(.httpRequest.status >= 200) | ."logging.googleapis.com/trace"'
projects/planner-dev/traces/4bf92f3577b34da6a3ce929d0e0e4736
```

The one entry with a request, and its trace: the value lesson 11 uses to open the trace of that order.

## The rest of the language, briefly

| expression | selects |
|---|---|
| `jsonPayload.order_id="o-1002"` | entries whose payload field equals the value |
| `jsonPayload.message:"retried"` | `:` is "contains", for text |
| `textPayload=~"stock .* failed"` | `=~` is a regular expression |
| `NOT severity=DEFAULT` | `NOT`, `AND` and `OR` combine; `OR` must be written |
| `timestamp>="2026-10-30T12:00:00Z"` | a time, though the Explorer's time picker is the usual way |

**Filter on `resource` and `severity` first, payload fields last.** The first two are indexed and narrow the
search quickly; a query that starts with `jsonPayload.message:"…"` over a month of logs reads all of them.
