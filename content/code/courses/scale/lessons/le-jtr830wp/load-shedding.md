---
title: Load shedding, everybody together
version: 1
---

A rate limit per buyer does nothing about ten thousand buyers who each stay inside their own limit.
What protects the box office from all of them together is a cap on **how much work it takes on at
once**, and a refusal for whatever is over it. That is **load shedding**: when the box office is
full, the next request is turned away at the door, cheaply, instead of being admitted to make every
request slower and, as section 02 showed, to break the database.

`guards.Shed` holds 32 slots. A request takes a free slot or is answered `503 Service Unavailable` at
once, and each slot keeps its own database connections, so **the slots bound the connections too**.
The same 128 workers as section 02, with the buyer limit raised for this run, because `load.py` is a
single anonymous buyer and only one guard is being measured here:

```
ana@lab:~/tickets$ docker compose up -d --scale app=1
 Container tickets-collector-1 Running 
 Container tickets-app-1 Running 
 Container tickets-prometheus-1 Running 
 Container tickets-payments-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-jaeger-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-2 Stopping 
 Container tickets-app-3 Stopping 
 Container tickets-app-2 Stopped 
 Container tickets-app-2 Removing 
 Container tickets-app-3 Stopped 
 Container tickets-app-3 Removing 
 Container tickets-app-2 Removed 
 Container tickets-app-3 Removed 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ BUYER_RATE=1000 BUYER_BURST=1000 docker compose up -d app
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
 Container tickets-replica-1 Running 
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
ana@lab:~/tickets$ python3 load.py -m POST -d 10 'http://localhost:8080/events/{event}/tickets' --events 50 -c 128
requests  1123 in 11.3 s = 99.3 per second
latency   p50 918.1 ms  p95 2501.5 ms  p99 3607.2 ms  max 4164.0 ms
status    201: 1017  503: 106
ana@lab:~/tickets$ docker compose exec db psql -U tickets -tAc "SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend'"
33
```

Compare it with the last run of section 02:

| | no guard | 32 slots |
|---|---|---|
| sold | 1003 | 1017 |
| refused | 146 × `500`, the database out of connections | 106 × `503`, at the door |
| database connections after the run | 52 | 33 |

**The failures changed kind.** Instead of a sale that got as far as the database and broke there, a
request that never started, answered with a status that means *busy, come back* and a `Retry-After`
saying when. **The database stayed inside its limit**: 33 connections, which are the 32 slots and
`psql`'s own. And a few more tickets were sold, because no sale was wasted on a connection that
failed.

**What did not change is the waiting**: the median request still took about a second. Shedding
protects what is behind the door; it does not make the CPU in front of it any faster. Here the wait
is before the door, in threads that have not had the CPU yet to reach it, and `load.py`'s workers
make sure it stays full: a worker that is refused asks again at once. A refusal lowers
the load only if the caller does something with it, which is section 06.

## Choosing the number

Too few slots and the box office refuses work it could have done; too many and the limit does not
bound anything that matters. The useful starting point is the resource being protected: the
database here, whose limit is 100 connections, shared by every copy. Three copies with 32 slots
each fit under it, with a little room left. Beyond a fixed number, there are
**adaptive limits** that measure latency and move the cap the way TCP moves its congestion window,
raising it while answers stay fast and cutting it when they slow down.
