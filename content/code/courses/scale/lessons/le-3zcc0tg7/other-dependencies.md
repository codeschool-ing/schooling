---
title: Redis and payments
version: 1
---

Redis stopped, and one sale:

```
ana@lab:~/tickets$ docker compose stop redis
 Container tickets-redis-1 Stopping 
 Container tickets-redis-1 Stopped 
ana@lab:~/tickets$ curl -s -X POST -H 'X-Buyer: fan-1' localhost:8080/events/1/tickets; echo
{"event": 1, "seat": 1, "code": "cb5ad8d5b5fd9bea"}
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep 'rate limit unavailable' | tail -1
{"time": "2026-10-10T19:40:01.465+00:00", "level": "warning", "message": "rate limit unavailable", "host": "615b3114daa0", "error": "Error -2 connecting to redis:6379. Name or service not known.", "trace_id": "d98603fe45bb6c8e1e5c740c50987fcf"}
ana@lab:~/tickets$ docker compose start redis
 Container tickets-redis-1 Starting 
 Container tickets-redis-1 Started 
```

**The sale went through**, and the log recorded that the rate limit could not be checked. For as
long as Redis is down, a bot can buy faster than two a second, and the decision made in lesson 9 is
that this is better than nobody buying at all.

Then payments stopped, six sales, and a read:

```
ana@lab:~/tickets$ docker compose stop payments
 Container tickets-payments-1 Stopping 
 Container tickets-payments-1 Stopped 
ana@lab:~/tickets$ for i in $(seq 6); do curl -s -w ' %{http_code}\n' -X POST -H "X-Buyer: fan-$i" localhost:8080/events/1/tickets; done
{"error": "payment failed"} 502
{"error": "payment failed"} 502
{"error": "payment failed"} 502
{"error": "payment failed"} 502
{"error": "payment failed"} 502
{"error": "payments unavailable"} 503
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' localhost:8080/events/1
{"name": "Show 1", "left": 999999, "host": "615b3114daa0", "source": "replica"} 200 in 0.002483 s
ana@lab:~/tickets$ docker compose start payments
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
```

Five sales failed with `502` after their three attempts each, then **the breaker opened** and the
sixth was refused at once. **The read took 2.5 ms**, as if nothing had happened, because nothing it
needs had. A box office without payments is a box office that can still show every show and every
seat count, which is most of what its visitors are doing at any moment.

What the buyer should see on the sale is a product decision rather than a technical one. *Payments
are not working right now, try again in a few minutes* is honest. Holding the seat for ten minutes
and charging when payments returns is kinder, and it is a different system: a reservation with an
expiry, a queue of charges, and a way to tell the buyer later whether it worked.
