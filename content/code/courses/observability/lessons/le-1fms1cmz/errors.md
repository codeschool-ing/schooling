---
title: When it fails: status and exceptions
version: 1
---

A trace earns its keep on the request that failed, so the shop is broken on purpose: `orders` is
stopped, and a checkout is sent.

```
ana@obs:~/shop$ docker compose stop orders
 Container shop-orders-1 Stopping 
 Container shop-orders-1 Stopped 
ana@obs:~/shop$ curl -s -w ' %{http_code}\n' -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json
{"error":"try again later"}
 503
ana@obs:~/shop$ docker compose start orders
 Container shop-orders-1 Starting 
 Container shop-orders-1 Started 
```

The customer got a `503` and a polite sentence. The storefront logged an error with the request's
trace id, and the trace says what the log only summarised:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront | grep unreachable | jq -c '{level, message, trace_id}'
{"level":"ERROR","message":"orders unreachable","trace_id":"76d585ac77c4564bdfae0e3aefa5e611"}
ana@obs:~/shop$ curl -s localhost:16686/api/traces/76d585ac77c4564bdfae0e3aefa5e611 | jq '.data[0].spans[0] | {tags: ([.tags[] | select(.key | test("^(otel.status|error)")) | {(.key): .value}] | add), events: [.logs[].fields | from_entries | {event, "exception.type"}]}'
{
  "tags": {
    "otel.status_code": "ERROR",
    "error": true,
    "otel.status_description": "orders unreachable"
  },
  "events": [
    {
      "event": "exception",
      "exception.type": "requests.exceptions.ConnectionError"
    }
  ]
}
```

**Two different things were recorded, by two calls in the storefront's code.** When `requests`
raised, the `except` block did this:

```python
            span.record_exception(e)
            span.set_status(Status(StatusCode.ERROR, "orders unreachable"))
```

`set_status` marks the span as failed, and backends turn that into the `error: true` Jaeger shows,
the red in every trace view and the filter *show me failed traces*. `record_exception` adds an
**event**: a timestamped note inside the span, here carrying the exception's type, message and
stack trace. An event is how a span says *this happened at this moment* without becoming a new
span.

A span's status has three values, and the rule for them is narrower than it looks:

| status | means | who sets it |
|---|---|---|
| `UNSET` | nobody said it failed | the default |
| `ERROR` | this operation failed | the instrumentation, when the operation failed |
| `OK` | somebody insists it succeeded | the application, rarely, to override an `ERROR` |

**A failure is the span's own, not its caller's.** The storefront answering `404` for an unknown
product is a correct refusal, and the code leaves the status alone. The same rule is written into
OpenTelemetry's HTTP conventions: a `4xx` marks the *client's* span as failed and not the
server's, because the server did its job. A `5xx` marks both. Mark every refusal as an error and
the error rate stops meaning *something is broken* and starts meaning *somebody typed a wrong
address*.
