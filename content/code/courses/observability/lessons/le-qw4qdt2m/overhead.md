---
title: What it costs
version: 1
---

Wrapping every database call and every HTTP request in a span is work, and "it is cheap" is a claim
to measure rather than repeat. `bench.py` sends 300 orders straight to `orders`, one after the
other, and reports how long each took. Each order is a real one: a database insert, a call to
payments, an update and a message on the queue.

```python
import statistics
import time

import requests

times = []
for n in range(300):
    start = time.perf_counter()
    requests.post("http://orders:8081/orders", timeout=5,
                  json={"sku": "tea-500g", "qty": 1, "total_cents": 3450, "card": "4111 1111 1111 1111"})
    times.append((time.perf_counter() - start) * 1000)
print(f"300 orders: median {statistics.median(times):.1f} ms, mean {statistics.mean(times):.1f} ms")
```

Run once against `orders` as the lab runs it, then again with the launcher taken away. Compose
reads `compose.override.yaml` on top of `compose.yaml` when it exists, which is how the command is
replaced without editing the main file:

```
ana@obs:~/shop$ docker compose run --rm sandbox python bench.py 2>/dev/null
300 orders: median 25.1 ms, mean 26.0 ms
ana@obs:~/shop$ cat compose.override.yaml
services:
  orders:
    command: waitress-serve --port 8081 --threads 16 orders.app:app
ana@obs:~/shop$ docker compose up -d orders 2>&1 | tail -1
 Container shop-orders-1 Started 
ana@obs:~/shop$ docker compose run --rm sandbox python bench.py 2>/dev/null
300 orders: median 24.1 ms, mean 24.8 ms
ana@obs:~/shop$ rm compose.override.yaml && docker compose up -d orders 2>&1 | tail -1
 Container shop-orders-1 Started 
```

**25.1 milliseconds against 24.1 at the median**, and 26.0 against 24.8 on average: about one
millisecond per order, around four per cent, for four spans and their export. Most of an order's 25
milliseconds is the database and the call to payments, so the instrumentation is a small share of a
request that does real work. On a request that does almost nothing, a cache hit answered in a
tenth of a millisecond, the same fixed cost would be most of the time spent.

Two things this measurement does not say. It ran the batch processor, so exporting happened off the
request's path; lesson 2 showed what the simple processor would add. And it is one run of 300 on one
machine: **a difference of one millisecond is close to the noise between two runs**, which is itself
the useful conclusion. The cost worth worrying about is rarely the wrapping. It is a span per item
inside a loop of ten thousand, an attribute that serialises a whole object, or keeping every trace
of a busy service. Lesson 12 is about the last of those.
