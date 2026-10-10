---
title: Timeouts, the first guard on every call
version: 1
---

Every guard so far protects the box office from its callers. The next two protect it from what it
calls. A sale cannot finish until payments answers, and **a call with no deadline waits as long as
the other side takes**: Python's `urlopen` with no `timeout` waits forever. Lesson 8 gave the call
five seconds; this lesson gives it one.

Make payments slow, five seconds a charge, and buy one ticket:

```
ana@lab:~/tickets$ docker compose up -d app
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Healthy 
 Container tickets-db-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ PAYMENTS_DELAY_MS=5000 docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST -H 'X-Buyer: fan-1' localhost:8080/events/1/tickets
{"error": "payment failed"} 502 in 1.026242 s
ana@lab:~/tickets$ sleep 12
ana@lab:~/tickets$ python3 trace.py
trace f6c754085051d13924a9513c9a6601d0
POST /events/{id}/tickets      tickets   at   0.0 ms  took 1023.8 ms
  charge                       tickets   at   4.9 ms  took 1018.1 ms
    POST /charges              payments  at  17.9 ms  took 5602.2 ms
```

The buyer got a `502` after **1.03 seconds** instead of waiting five. Now read the trace. The box
office's `charge` span ended after 1,018 ms, when it gave up. Payments' own span, in the same trace,
**took 5,602 ms**: it went on charging after the box office had stopped listening.

**A timeout ends the wait, not the work.** The card was charged and the buyer was told the payment
failed. Whether to try again, and how to try again without charging twice, is exactly lesson 10's
subject; for now, note that a timeout always leaves the caller not knowing whether the work was done.

## Choosing a deadline

A timeout has two sides to satisfy:

- **above how long the dependency normally takes**, at a high percentile, or the timeout fails calls
  that would have succeeded. Payments normally answers in 20 to 40 ms, so one second leaves a wide
  margin;
- **below how long the caller will wait**, or the answer arrives for nobody. A buyer looking at a
  spinner gives up within seconds.

And it has a cost while it runs: **a sale waiting for payments holds one of the 32 slots** for the
whole second. With payments hanging, the box office can complete at most 32 slow failures a second,
and every other request is shed. When one request calls several services in turn, the usual
arrangement is a **deadline** for the whole request, passed along, so each call gets what is left
of it rather than a full timeout of its own.
