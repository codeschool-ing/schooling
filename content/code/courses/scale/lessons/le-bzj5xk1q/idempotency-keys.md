---
title: Idempotency keys
version: 1
---

The fix is to give each operation a name. The box office makes a random **idempotency key** for each
sale, once, before the first attempt, and sends it with every attempt in an `Idempotency-Key`
header. Payments remembers the keys it has seen and the answer each one got. A request with a new
key is charged; a request with a known key gets the stored answer, and nothing is charged again.
Payment providers' public APIs, Stripe's among them, work exactly this way.

The same run, keys on, after restarting payments to empty its memory and its count:

```
ana@lab:~/tickets$ docker compose restart payments
 Container tickets-payments-1 Restarting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ docker compose up -d app
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
requests  45 in 10.8 s = 4.2 per second
latency   p50 894.0 ms  p95 1211.5 ms  p99 1218.5 ms  max 1218.5 ms
status    201: 45
ana@lab:~/tickets$ curl -s localhost:8001/charges; echo
{"charged": 45}
```

**45 tickets sold, 45 charges.** The timeouts and the retries happened as before; what changed is
that each retry was answered with the first attempt's result.

## The details that make it work

- **The key belongs to the operation, not to the request.** Made once per sale, before the loop. A key
  made per attempt would be a different name for every retry, and the duplicates would come back.
- **A key still running is waited for.** A retry often arrives while the first attempt is still
  being charged, which is exactly the timeout case. Payments makes the retry wait for the first
  attempt and answers with its result. Some services answer `409 Conflict` instead and let the
  caller retry later; what they must not do is start a second charge.
- **Remembered for long enough, and somewhere durable.** This payments keeps keys in memory, which
  is why a restart empties it. A real one stores them in its database, often for 24 hours, written
  in the same transaction as the charge, so that a crash between charging and remembering cannot
  happen.
- **The same key with a different request is an error.** If a key arrives with a different amount, a
  careful service refuses it rather than answering with a charge for something else.

Some operations need no key because they are idempotent by nature: setting a seat's state to
*reserved*, deleting a reservation, `PUT` and `DELETE` as HTTP defines them. Designing an operation
that way, *set* rather than *add*, is often simpler than remembering keys, and it is worth asking
first.
