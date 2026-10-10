---
title: Exponential backoff
version: 1
---

How long should the box office wait before trying again? Waiting nothing is the worst answer: a
service that is overloaded receives every failed request again at once, on top of the new ones, and
the overload that caused the failure is now larger. A fixed wait is better, and still wrong when
the problem lasts longer than the wait.

**Exponential backoff** doubles the wait after every failed attempt. The box office's ceiling is
100 ms × 2ⁿ for attempt *n*: 200 ms after the first failure, 400 ms after the second, and never more
than two seconds. A short problem costs a short wait; a long one is retried less and less often,
which is what gives the other side room to recover.

Make every call to payments fail, and buy one ticket:

```
ana@lab:~/tickets$ PAYMENTS_FAIL_PERCENT=100 docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST localhost:8080/events/1/tickets
{"error": "payment failed"} 502 in 0.341069 s
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep 'charge retry' | tail -2
{"time": "2026-10-10T07:43:16.992+00:00", "level": "warning", "message": "charge retry", "host": "6bc51142e2fa", "attempt": 1, "wait_ms": 131, "error": "HTTPError: HTTP Error 503: Service Unavailable", "trace_id": "4c5b53d3f5228de06cd7d4d9da6f9e27"}
{"time": "2026-10-10T07:43:17.127+00:00", "level": "warning", "message": "charge retry", "host": "6bc51142e2fa", "attempt": 2, "wait_ms": 194, "error": "HTTPError: HTTP Error 503: Service Unavailable", "trace_id": "4c5b53d3f5228de06cd7d4d9da6f9e27"}
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py
trace 4c5b53d3f5228de06cd7d4d9da6f9e27
POST /events/{id}/tickets      tickets   at   0.0 ms  took 339.4 ms
  charge                       tickets   at   0.8 ms  took   4.6 ms
    POST /charges              payments  at   3.0 ms  took   0.2 ms
  charge                       tickets   at 137.0 ms  took   3.4 ms
    POST /charges              payments  at 139.2 ms  took   0.2 ms
  charge                       tickets   at 335.4 ms  took   3.5 ms
    POST /charges              payments  at 337.7 ms  took   0.2 ms
```

The sale failed after **0.34 s** with three attempts, and the log and the trace say how the time was
spent. Each attempt took a few milliseconds and payments answered `503` in 0.2 ms. Between them the
box office waited **131 ms**, then **194 ms**. Those are not 200 and 400: each wait is a random
number between zero and the ceiling, and section 06 is why.

Two more rules sit in `backoff`. **A `Retry-After` from payments wins**: if the callee says when to
come back, the caller has no better information. And **the total is bounded**: three attempts means at most two waits, each
under its ceiling unless payments asked for longer, because the buyer is waiting behind them, and so
is one of the box office's 32 slots.
