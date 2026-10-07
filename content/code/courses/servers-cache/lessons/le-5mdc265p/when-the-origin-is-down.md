---
title: When the origin is down
version: 1
---

The edge checks the origin's health every two seconds through the `.probe` in the backend definition,
and `beresp.grace = 1h` keeps every expired object for an hour after its lifetime ends. Together they are
Varnish's form of lesson 6's `proxy_cache_use_stale`. With a lifetime of five seconds, let a copy
expire and stop the shops:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/7 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=5
X-Varnish: 32803
Age: 0
X-Cache: MISS
ana@web:~$ sleep 6; sudo systemctl stop shop@1 shop@2; sleep 5; sudo varnishadm backend.list
Backend name   Admin    Probe    Health    Last change
boot.origin    probe    0/3      sick      Wed, 07 Oct 2026 04:17:31 GMT

ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/7 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=5
X-Varnish: 37 32804
Age: 11
X-Cache: HIT
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: ipelivros.example' http://localhost:6081/api/books/8
503
```

The probe marked the origin **sick** after two failures out of the last three checks, and the edge
served book 7 as a `HIT` that was **eleven seconds old**, six past its lifetime, rather than an error.
Book 8, never fetched, has nothing in grace, and the edge answered it `503`. Start the shops again, and
the probe marks the origin healthy within a few seconds without anybody touching the edge.

Grace does a second job while the origin is healthy: when a popular copy expires, the edge serves it from
grace to everybody who asks while **one** request fetches the new copy, and Varnish queues identical
requests behind the fetch already in progress instead of sending each to the origin. That is how an
edge protects an origin from its own traffic, and lesson 11 measures the difference it makes.

## Counting

`varnishstat` keeps the counters for everything this lesson did:

```
ana@web:~$ sudo varnishstat -1 -f MAIN.cache_hit -f MAIN.cache_miss -f MAIN.cache_hitpass -f MAIN.s_pass -f MAIN.n_object -f MAIN.backend_req | awk '{print $1, $2}'
MAIN.cache_hit 12
MAIN.cache_hitpass 0
MAIN.cache_miss 11
MAIN.n_object 7
MAIN.s_pass 5
MAIN.backend_req 15
```

Twelve hits, eleven misses and five passes (the requests with cookies and credentials), 15 requests to
the origin, and seven objects stored. On a real edge the same counters, summed across all its cities,
are the hit ratio on the CDN's dashboard. **The origin's request count is the number to watch**: it is
what the edge is for, and a CDN bill with a high hit ratio and an origin that is still busy means
something is being passed that should not be.
