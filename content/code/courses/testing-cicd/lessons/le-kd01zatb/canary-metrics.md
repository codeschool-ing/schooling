---
title: What to compare, and against what
version: 1
---

The canary above was judged by one number per side: the share of requests that failed. Green's
2.0% meant something only because blue, **at the same time, on the same mix of requests**, showed
0.0%. A canary is a comparison, never a threshold on its own.

## Against the baseline, not against a target

Suppose the rule were "stop if green's error rate is above 3%". Green's 2.0% would pass, and the
release would go on to 100% with its bug. Suppose instead the shop had a bad minute, with the
carrier slow and both sides failing 4%: the rule would stop a release that was perfectly fine.

Comparing with blue removes both mistakes. Whatever the traffic, the time of day or the state of the
carrier, both sides meet it together, and the question becomes **is green worse than blue?** That
is what `ops/canary.py` in the lab encodes: it stops when green's error rate exceeds blue's by more
than one percentage point. Lesson 11 runs it.

## What to measure

- **Errors**: the share of requests answered with a 5xx, or not answered. The one used here.
- **Latency**: not the average, which hides the slow few, but a high percentile such as the 99th.
  A release that makes one request in a hundred take five seconds has an average that barely moves.
- **Saturation**: memory, CPU, open connections. A leak shows here hours before it shows anywhere
  else.
- **The business**: quotes that turn into orders, payments that complete. A release can answer
  every request with a 200 and a wrong price. Of these four, only this one would notice.

## Pitfalls

- **Requests are not customers.** The lab's router picks a side per request id, so one customer
  making five requests may meet both versions. Real canaries usually pick by customer, which keeps
  each customer on one side and makes their experience consistent.
- **Different traffic.** If the canary gets only internal users, or only one region, its numbers
  describe them. A canary should get a random slice of the real mix.
- **Too early.** The first minutes after a start include warm-up: caches empty, connections being
  opened. Judging on them blames the release for being new.
