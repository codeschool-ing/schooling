---
title: Planning an on-sale
version: 1
---

Suppose Sabiá Ingressos puts a stadium show on sale at ten in the morning: 20,000 seats, and the
last show of that size brought about 6,000 buyers in the first minute. A plan answers one question: **how
many copies of the box office, and what else has to change, so that the first minute stays under
70%?**

## What one copy can do

Measure it, rather than guess. One copy, the per-buyer limit lifted, reads and then sales:

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
ana@lab:~/tickets$ python3 load.py 'http://localhost:8080/events/{event}' --events 50 -c 16 -d 10
requests  8990 in 10.0 s = 898.0 per second
latency   p50 14.2 ms  p95 41.5 ms  p99 61.8 ms  max 202.1 ms
status    200: 8990
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 16 -d 10
requests  1020 in 10.1 s = 101.2 per second
latency   p50 167.0 ms  p95 264.4 ms  p99 310.5 ms  max 410.4 ms
status    201: 998  409: 22
```

One copy, one CPU, answers about **900 reads a second** or about **100 sales a second**. That
makes a read cost about 1.1 ms of the CPU and a sale about 10 ms: the signing, the queries and the
call to payments. The 22 refusals were for show 7, which section 07 sold out.

## What the minute asks for

Suppose the last on-sale's logs say that a buyer in the first minute loads a show page about 10
times and tries to buy about once. So 6,000 buyers in 60 seconds is:

| | per second | CPU each | CPU per second |
|---|---|---|---|
| reads | 6,000 × 10 ÷ 60 = 1,000 | 1.1 ms | 1.1 s |
| sales | 6,000 × 1 ÷ 60 = 100 | 10 ms | 1.0 s |
| total | | | **2.1 CPUs** |

## From demand to copies

- **At 100% busy**, 2.1 copies would do. Section 09 is why that is not a plan.
- **At 70%**, 2.1 ÷ 0.7 = **3 copies**.
- **One more for failure**: if a copy dies at 10:00:30, the other three must carry the minute. At
  2.1 ÷ 3 = 70% they can. **4 copies**, which is the rule called **N + 1**.

## What else the plan finds

Copies are the easy part. The plan has to walk every resource they share:

- **Database connections.** 4 copies × 32 slots = 128 connections, and the primary allows 100. The
  plan has to change: 24 slots per copy gives 96, or a connection pooler such as PgBouncer in front of
  the primary lets many slots share few connections.
- **The primary.** Every sale is an `UPDATE` of the same show's row, the hot row of lesson 1, which
  measured one row's limit at about 138 sales a second. 100 is already close. If 6,000 becomes 20,000, no number of
  copies helps, and the answer is lesson 2's partitioning of the seats or a queue in front of the sale.
- **Payments.** 100 charges a second at 30 ms is 3 in flight; their contract says how many they
  accept, and that number is part of the plan too.
- **The buyers who do not get in.** 6,000 buyers for 20,000 seats is fine. 60,000 is not, and the
  plan is then lesson 9's waiting room, decided before ten o'clock rather than during it.

## And then verify it

Every number above is a measurement of one copy, multiplied. A plan is a hypothesis about how the
whole system behaves under the whole load, and the only way to test it before ten o'clock is to send
the whole load. That is lesson 12.
