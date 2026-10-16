---
title: The first thing to break
version: 1
---

The fix is one setting. Raise each nginx worker's connections to 4,096, in `nginx.conf`, and
restart the load balancer:

```conf
# nginx.conf
events {
  worker_connections 4096;
}

http {
  upstream app {
    server app:8000;
    keepalive 64;
  }

  server {
    listen 80;
    location / {
      proxy_pass http://app;
      proxy_http_version 1.1;
      proxy_set_header Connection "";
    }
  }
}
```

Then 400 a second again:

```
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none -e RATE=400 -e DURATION=15s - < sale.js
asked     400 a second for 15s
answered  3804 = 180.9 a second
latency   p50 2895.1 ms  p95 8894.4 ms  p99 12486.8 ms  max 18205.8 ms
sold 3367  refused 437  failed 0  never sent 2197
```

**No failures.** Every request that reached the box office was answered: 3,367 sold and 437
refused at the door. And now the numbers say what is really happening at 400 a second: the box
office answered **181 a second**, which is its capacity on this machine, and every sale waited in
line for it, a median of 2.9 s.

There is a new figure too: **2,197 never sent**. With answers taking seconds, k6's 1,000 virtual
users were all waiting at once, and the arrivals it could not start were dropped. That is the test
reaching a limit of its own, and it means this run asked for less than 400 a second in practice. A
load test has to watch its own generator as closely as the system: a run whose generator was the
bottleneck measured the generator.

What the fix did not do is make the box office faster. It moved the failure from *dropped by
nginx, with nothing logged anywhere a person would look* to *answered by the box office*, either
with a ticket or with a `503` that says it was busy. That is lesson 11's rule applied to
infrastructure: **the failure you want is the one that says what happened**. And it is the general
result of stress testing: the limit you find first is rarely the one you planned for, and the second
is often the one you did.

