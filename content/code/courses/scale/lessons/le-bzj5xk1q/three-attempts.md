---
title: Three attempts
version: 1
---

Make payments fail one call in ten, at once and without charging, as a payment service does when it
is shedding load. First with a single attempt, then with the default of three. `load.py` is a single
anonymous buyer, so lesson 9's per-buyer limit is lifted for the whole lesson:

```
ana@lab:~/tickets$ export BUYER_RATE=1000 BUYER_BURST=1000
ana@lab:~/tickets$ PAYMENTS_FAIL_PERCENT=10 docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ CHARGE_ATTEMPTS=1 docker compose up -d app
 Container tickets-replica-1 Running 
 Container tickets-db-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-replica-1 Healthy 
 Container tickets-db-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 4 -d 10
requests  972 in 10.0 s = 96.8 per second
latency   p50 43.6 ms  p95 55.4 ms  p99 62.7 ms  max 102.5 ms
status    201: 886  502: 86
ana@lab:~/tickets$ docker compose up -d app
 Container tickets-db-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
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
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 4 -d 10
requests  719 in 10.2 s = 70.7 per second
latency   p50 45.9 ms  p95 147.4 ms  p99 243.5 ms  max 483.6 ms
status    201: 719
```

With one attempt, **86 sales of 972 failed**, about one in ten, as asked. With three attempts,
**none of 719 failed**. If each attempt fails independently one time in ten, a sale fails only when
all three do, and 0.1³ is one in a thousand: about one expected sale in 719, and this run got none.

The price is in the second run's other numbers. The median sale barely moved, but the 95th
percentile went from 55 to 147 ms and the 99th from 63 to 244 ms: the sales that needed a second or
third attempt paid for the waits in between. The rate fell too, from 97 to 71 sales a second,
because `load.py`'s four workers spent part of their time waiting for those sales. **Retries trade
latency in the tail for successes**, and that is usually the right trade for a purchase, where a
buyer prefers a slower ticket to an error.

Note also what did not happen: lesson 9's breaker never opened. It counts the failures of a whole
sale, after its retries, so a payment service that fails one call in ten looks healthy to it, which
it is.
