---
title: Rate limits, one caller at a time
version: 1
---

A **rate limit** caps how often one caller may ask. At a ticket box office the caller worth limiting
is the bot that tries to buy a whole show in the first second of an on-sale; elsewhere it is an API
key, an account, or an address. The box office limits **purchases per buyer**, identified here by
an `X-Buyer` header, where a real system would use the signed-in account.

## The token bucket

The usual algorithm is a **token bucket**. Each buyer has a bucket that holds at most `burst`
tokens and refills at `rate` tokens a second. A purchase takes a token; with none left it is refused,
and the time until the next token tells the caller when to come back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A bucket for one buyer holding at most five tokens. Tokens drip in from above at two a second. Each purchase takes one token out at the bottom and goes ahead; a purchase that finds the bucket empty is refused with 429 and a Retry-After of the time until the next token.\"><text x=\"250\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">rate: 2 tokens a second</text><path d=\"M250 34 L250 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M250 62 L247.0 55.7 L253.0 55.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><path d=\"M 170 70 L 185 190 L 315 190 L 330 70\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"205\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"227\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"249\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"271\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"293\" cy=\"175\" r=\"9\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"345\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">burst: 5</text><path d=\"M250 192 L250 222\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M250 222 L247.0 215.7 L253.0 215.7 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"250\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">each purchase takes one</text><rect x=\"470\" y=\"60\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">token left</text><text x=\"580\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→ the sale goes ahead</text><rect x=\"470\" y=\"140\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">bucket empty</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→ 429, Retry-After</text></svg>", "caption": "A token bucket: the rate refills it, the burst is its size."}
```

Two numbers, two meanings. `rate` is the long-run limit, here two purchases a second. `burst` is how
much a quiet caller may do at once, here five, so somebody buying tickets for a family is not
punished for clicking quickly. The alternatives behave worse at the edges. A **fixed window**, at
most 120 per minute counted per clock minute, lets a caller send 120 at 10:00:59 and 120 more at
10:01:00. A **leaky bucket** queues requests and lets them out at a steady rate, which is what nginx's
own `limit_req` does; it smooths traffic rather than refusing it.

## Trying it

This program plays one buyer clicking as fast as it can, and counts the answers second by second.
Save it as `attempts.py`:

```python
# attempts.py
"""One buyer trying to buy as fast as it can, counted second by second."""
import argparse
import http.client
import time
from collections import Counter

p = argparse.ArgumentParser()
p.add_argument("buyer")
p.add_argument("-d", "--seconds", type=int, default=5)
p.add_argument("--event", type=int, default=1)
args = p.parse_args()

conn = http.client.HTTPConnection("localhost", 8080)
retry_after = None
seconds = [Counter() for _ in range(args.seconds)]
start = time.monotonic()
while (elapsed := time.monotonic() - start) < args.seconds:
    conn.request("POST", f"/events/{args.event}/tickets",
                 headers={"X-Buyer": args.buyer, "Content-Length": "0"})
    answer = conn.getresponse()
    answer.read()
    seconds[int(elapsed)][answer.status] += 1
    if answer.status == 429:
        retry_after = answer.getheader("Retry-After")

for n, counts in enumerate(seconds):
    print(f"second {n + 1}  " + "  ".join(f"{s}: {c:3}" for s, c in sorted(counts.items())))
total = sum(seconds, Counter())
print(f"bought {total[201]}, refused {total[429]}, last Retry-After {retry_after} s")
```

The bot, for five seconds:

```
ana@lab:~/tickets$ python3 attempts.py bot-7
second 1  201:   6  429: 516
second 2  201:   2  429: 585
second 3  201:   2  429: 712
second 4  201:   2  429: 724
second 5  201:   2  429: 766
bought 14, refused 3303, last Retry-After 1 s
ana@lab:~/tickets$ python3 attempts.py fan-12 -d 2
second 1  201:   6  429: 598
second 2  201:   2  429: 691
bought 8, refused 1289, last Retry-After 1 s
```

**Six purchases in the first second**: the five in the full bucket, and one more that dripped in
while the bot spent them. **Then two a second**, exactly the rate, and between 500 and 800 refusals a
second in between, each answered `429 Too Many Requests` with `Retry-After: 1`. Fourteen in five seconds,
which is five plus two a second for the four and a half seconds after the first. A second buyer,
`fan-12`, is not touched by the bot's empty bucket: each key has its own.

## Why the bucket is in Redis

A limit kept in each copy's memory is a limit per copy. Behind nginx, with three copies, the bot
would get three buckets and three times the rate, and the limit would change every time somebody
changed the number of copies. So the bucket lives in Redis, and every copy asks the same one:

```
ana@lab:~/tickets$ docker compose up -d --scale app=3
 Container tickets-prometheus-1 Running 
 Container tickets-app-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-payments-1 Running 
 Container tickets-collector-1 Running 
 Container tickets-jaeger-1 Running 
 Container tickets-app-3 Creating 
 Container tickets-app-2 Creating 
 Container tickets-app-3 Created 
 Container tickets-app-2 Created 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-3 Starting 
 Container tickets-app-3 Started 
 Container tickets-app-2 Starting 
 Container tickets-app-2 Started 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ python3 attempts.py bot-9
second 1  201:   6  429: 490
second 2  201:   2  429: 635
second 3  201:   2  429: 592
second 4  201:   2  429: 462
second 5  201:   2  429: 611
bought 14, refused 2790, last Retry-After 1 s
```

Three copies, and the same fourteen purchases in five seconds. The price is a network round trip to
Redis on every sale, and a decision about what happens when Redis is down. The box office **fails
open**: if Redis cannot answer, the sale goes ahead and a warning is logged. This limit is about
fairness between buyers, and refusing every sale because the fairness check is down would turn a
Redis outage into a box office outage. A limit that protects something fragile, like an expensive
search, might reasonably fail closed instead.
