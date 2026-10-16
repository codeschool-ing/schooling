---
title: Charged twice
version: 1
---

A retry after a timeout sends the same request again, and the timeout said nothing about whether the
first one did its work. Lesson 9 measured it: the box office gave up at one second and payments
finished the charge at 5.6. A charge is not **idempotent**: doing it twice is not the same as doing
it once.

Make payments slow, 600 to 1,200 ms a charge, so that about a third of the charges outlast the box
office's one-second timeout. Then turn the idempotency keys off, sell for ten seconds, and ask
payments how many charges it made:

```
ana@lab:~/tickets$ PAYMENTS_DELAY_MS=600 docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ IDEMPOTENCY_KEYS=off docker compose up -d app
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 4 -d 10
requests  35 in 11.6 s = 3.0 per second
latency   p50 885.4 ms  p95 2871.1 ms  p99 3545.2 ms  max 3545.2 ms
status    201: 34  502: 1
ana@lab:~/tickets$ curl -s localhost:8001/charges; echo
{"charged": 48}
```

**34 tickets sold, 48 charges.** Fourteen charges were for sales that had already been charged:
the box office timed out, retried, and payments, with no way to know the second request was the
first one again, charged the card again. One sale failed after three timeouts, and was very likely
charged anyway. Every one of those buyers would see two or three charges on a statement for one
ticket, and nothing in the box office's own records would say so: it logged a few retries, and sold
34 tickets.

The retries were not the bug. Without them this run would have failed a third of its sales; with
them it sold almost all of them. **The bug is retrying an operation that is not safe to repeat**, and
the fix is to make it safe.
