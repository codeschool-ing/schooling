---
title: Coordinated omission
version: 1
---

The difference between the two models is sharpest when the system stops. `docker compose pause`
freezes a container where it stands: every process in it stops, connections stay open, nothing is
answered. Pause the box office for two seconds in the middle of a run, first under `load.py` with
four workers, then under k6 at fifty a second. The pause is started in the background, five seconds
in:

```
ana@lab:~/tickets$ export BUYER_RATE=100000 BUYER_BURST=100000
ana@lab:~/tickets$ docker compose up -d app
 Container tickets-db-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-replica-1 Running 
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
ana@lab:~/tickets$ (sleep 5; docker compose pause app; sleep 2; docker compose unpause app) >/dev/null 2>&1 & python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 4 -d 15; wait
requests  1342 in 15.0 s = 89.3 per second
latency   p50 38.2 ms  p95 48.0 ms  p99 59.4 ms  max 2148.4 ms
status    201: 1342
ana@lab:~/tickets$ (sleep 5; docker compose pause app; sleep 2; docker compose unpause app) >/dev/null 2>&1 & docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none -e DURATION=15s - < sale.js; wait
asked     50 a second for 15s
answered  745 = 49.6 a second
latency   p50 41.5 ms  p95 1871.5 ms  p99 2146.7 ms  max 2196.9 ms
sold 745  refused 0  failed 0  never sent 5
```

The same two-second freeze, measured twice:

| | load.py, closed | k6, open |
|---|---|---|
| 95th percentile | 48 ms | 1,872 ms |
| 99th percentile | 59 ms | 2,147 ms |
| max | 2,148 ms | 2,197 ms |

**`load.py` says the freeze barely happened.** Its four workers each had one request in flight when
the box office froze; those four took two seconds, and then the workers carried on. Four slow
answers out of 1,342 do not reach the 99th percentile. **k6 says more than one sale in twenty took
nearly two seconds**, because during the freeze a hundred buyers arrived, at fifty a second, and every one of
them waited.

The second answer is the true one. A buyer arriving during those two seconds waited, and the
closed test did not send that buyer at all: its workers were stuck waiting too, so the requests
that would have been slow were never made, and never measured. This is called **coordinated
omission**, a name from Gil Tene: the load generator coordinates with the system it is measuring
and omits exactly the samples that matter. Every closed-loop tool has it, and so do latency numbers
from a client that retries or queues on its own side.

There are two ways out. Use an open model, as k6 does here. Or, in a closed tool, measure each
request from the time it **should** have been sent, on a fixed schedule, rather than from the time
it was. Either way, the question to ask of any latency number is: *were the requests sent when the
users would have sent them?*
