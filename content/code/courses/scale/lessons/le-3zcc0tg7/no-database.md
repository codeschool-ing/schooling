---
title: No database at all
version: 1
---

Now the primary as well. A read of show 1, which this copy has read before; a read of show 2, which
it has not; and a sale:

```
ana@lab:~/tickets$ docker compose stop db
 Container tickets-db-1 Stopping 
 Container tickets-db-1 Stopped 
ana@lab:~/tickets$ sleep 5
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "memory", "seconds_old": 6}
ana@lab:~/tickets$ curl -s localhost:8080/events/2; echo
{"error": "event unavailable"}
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/1/tickets; echo
{"error": "sales paused"}
```

- **Show 1 was answered from memory**, six seconds old, and the answer says so. For a page showing
  how many seats are left, a six-second-old number is far better than an error, and a page that
  shows it can say *about 1,000,000 left*.
- **Show 2 had never been read**, so there was nothing to answer with: `503`, come back in five
  seconds. A cache can only return what it has seen.
- **The sale was paused** before anything was charged. Selling needs the primary; nothing else
  knows which seats are free.

Then both databases back:

```
ana@lab:~/tickets$ docker compose start db replica
 Container tickets-db-1 Starting 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "replica"}
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "replica"}
```

Reads came from the replica again at once, with nobody having to switch anything back: every
request tries the replica first, so the box office returns to normal as soon as the replica does.
That is the second half of a fallback, and the half most often forgotten: **coming back is
automatic, or it does not happen at three in the morning**.

## What memory cannot do

The last answer seen is kept by each copy for itself, forever, and only for shows that copy has
read. A real system uses a shared cache with an expiry for this, Redis or a CDN, and sets the
expiry to how stale it can bear to be. The idea is the same: decide in advance how old an answer
may be and still be worth giving.
